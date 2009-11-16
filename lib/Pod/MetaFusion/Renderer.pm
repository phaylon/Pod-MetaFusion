use MooseX::Declare;

class Pod::MetaFusion::Renderer {

    use MooseX::Types::Moose            qw( Object HashRef Int );
    use List::AllUtils                  qw( uniq );
    use Moose::Util                     qw( find_meta );
    use Moose::Util::TypeConstraints    qw( find_type_constraint );
    use Text::Balanced                  qw( extract_delimited extract_bracketed );
    use Scalar::Util                    qw( blessed );

    use aliased 'Pod::MetaFusion::Report';
    use aliased 'Pod::MetaFusion::Module::Spec';

    has report => (
        is          => 'ro',
        isa         => Report,
        required    => 1,
    );

    has section_order_map => (
        is          => 'ro',
        isa         => HashRef[Int],
        lazy_build  => 1,
        init_arg    => 'section_order',
    );

    method _build_section_order_map {

        return {
            synopsis        => -100,
            description     => -10,
            envmarks        => 500,
            see_also        => 750,
            authors         => 760,
            contributors    => 770,
            license         => 800,
        };
    }

    method section_order () {

        my $map = $self->section_order_map;

        return sort { $map->{ $a } <=> $map->{ $b } } keys %$map;
    }

    method meta_from_field (Spec $spec, Str $name) {

        my $field = $spec->get_single_field($self->name_field);
        my $class = $field->[0];

        Class::MOP::load_class($class);
        return $class->can('meta') ? $class->meta : undef;
    #    return find_meta $class;
    }

    method render (Spec $spec) {

        my @sections;
        
        for my $section (uniq $self->section_order) {

            if (my $method = $self->can("render_${section}_section")) {
                push @sections, $self->$method($spec);
            }
        }

        my $full = join "\n", @sections, '', '=cut';
        $full =~ s/\n\n\n+/\n\n/g;
        return $full;
    }

    method get_package_from_type (Object $type_constraint) {

        return $type_constraint->class
            if $type_constraint->isa('Moose::Meta::TypeConstraint::Class');

        return $type_constraint->role
            if $type_constraint->isa('Moose::Meta::TypeConstraint::Role');

        return undef;
    }

    method _deparse_type (Str $body, Str :$local_package?) {
        $local_package ||= '';

        my $done;

        while (length $body) {

            if ($body =~ /\A"/) {
                (my $found, $body) = extract_delimited $body, '"', '';

                $done .= qq{"$found"} if defined $found;
            }
            elsif ($body =~ /\A\[/) {
                (my $found, $body) = extract_bracketed $body, '["]';

                if (defined $found) {

                    if ($found =~ /\A \[ (.*) \] \Z/x) {
                        my $content = $1;
                        $done .= sprintf '[%s]', $self->_deparse_type($content);
                    }
                    else {
                        $done .= $found;
                    }
                }
            }
            elsif ($body =~ s/\A([a-z0-9_:]+)//i) {
                my $type_name = $1;

                my $tc = find_type_constraint $type_name;

                if ($tc) {

                    if (my $package = $self->get_package_from_type($tc)) {

                        $done .= sprintf 'L<%s>', $package;
                    }

                    elsif ($type_name =~ /::/) {

                        my @parts = split /::/, $type_name;
                        my $type  = pop @parts;
                        my $lib   = join '::', @parts;

                        $done .= sprintf 'L<%s|%s/%s>',
                            $type,
                          ( ($local_package eq $lib) ? '' : $lib ),
                            $type;
                    }
                    else {
                        $done .= $type_name;
                    }
                }
                else {
                    $done .= $type_name;
                }
            }
            else {
                $body =~ s/\A(.)//sm;
                $done .= $1;
            }
        }

        return $done;
    }

    method trim_string ($string) {
        my $text = "$string";
        $text =~ s/(?: \A[\s]+ | \s+\Z )//gx;
        return $text;
    }

    method render_type_constraint (Object $type_constraint, Str :$local_package?) {

#        warn "TC $type_constraint";
#        warn "BL " . blessed($type_constraint)
        my $name = "$type_constraint";#$type_constraint->name;
        return $self->_deparse_type($name, local_package => $local_package || '');

#        if ($name =~ /\A ([a-z0-9_:]+) (.*) \Z /xi) {
#            my $found = $1;
#            my $rest  = $2;
#
#            if ($tc->isa('Moose::Meta::TypeConstraint::Class')) {
#                return sprintf 'L<%s|%s>%s', $found, $tc->class, $rest;
#            }
#
#            if ($found =~ /::/) {
#
#                if ($rest =~ /\A \[ (.+) \] \Z/x) {
#
#                    my @rest_parts = split/,/, $1;
#                    $rest = sprintf '[%s]', join ',', map { 
#                        my $type = find_type_constraint $_;
#                        $type ? $self->render_type_constraint($type) : $_
#                    } @rest_parts;
#                }
#
#                my @parts = split /::/, $found;
#                my $type  = pop @parts;
#                my $lib   = join '::', @parts;
#                return sprintf 'L<%s|%s/%s>%s', $type, $lib, $type, $rest;
#            }
#        }

        return $name;
    }

    method render_list (@parts) {

        my @items;

        while (my $name = shift @parts) {
            my $content = shift @parts;

            push @items,
                sprintf('=item * %s', $name),
                '',
                $content,
                '';
        }

        return join("\n", 
            '=over',
            '',
            @items,
            '=back',
            '',
        );
    }

    method render_section (Str $name, Str $content) {

        return join("\n",
            '',
            sprintf('=head1 %s', uc $name),
            '',
            $content,
            '',
        );
    }

    method render_content_field (Spec $spec, Str $field_name) {

        my $field = $spec->get_single_field($field_name, optional => 1)
            or return;

        return $self->render_section($field_name => $field->[1]);
    }

    method render_description_section (Spec $spec) {

        return $self->render_content_field($spec, 'description');
    }

    method render_synopsis_section (Spec $spec) {

        return $self->render_content_field($spec, 'synopsis');
    }

    method render_authors_section (Spec $spec) {

        return $self->render_content_field($spec, 'authors');
    }

    method render_contributors_section (Spec $spec) {

        return $self->render_content_field($spec, 'contributors');
    }

    method render_see_also_section (Spec $spec) {

        my $see = $spec->get_field('see_also')
            or return;

        my @found;
        for my $link (@$see) {
            my ($target, $text) = @$link;

            push @found, sprintf('L<%s>', $target), $text;
        }

        return unless @found;
        return $self->render_section('see also', $self->render_list(@found));
    }

    method render_license_section (Spec $spec) {

        my $license = $spec->get_single_field('license', optional => 1)
            or return;

        my ($instead, $content) = @$license;

        return $self->render_section(
            'license and copyright',
            join("\n",
              ( $instead ? (
                    sprintf('See L<%s> for information about license and copyright.', $instead),
                    '',
              ) : () ),
                $content,
            ),
        );
    }

    method render_envmarks_section (Spec $spec) {

        my $classes = $spec->get_field('note_version')
            or return;

        my %classes = 
            map {
                my ($class) = @$_;
                Class::MOP::load_class($class);
                ($class, $class->VERSION);
            }
            @$classes;

        return(
            '=head1 ASSUMED VERSIONS',
            '',
            'This document has been rendered against the following prerequisites:',
            '',
            $self->render_list(
                map  { ($_, 'Version ' . $classes{ $_ }) }
                grep { defined $classes{ $_ } }
                sort { $classes{ $a } cmp $classes{ $b } }
                    keys %classes,
            ),
        );
    }

    method find_closest_named_class (Object $meta) {

        return $meta if $meta->isa('Moose::Meta::Role');

        for my $isa (map { find_meta $_ } $meta->linearized_isa) {

            return $isa
                unless $isa->is_anon_class;
        }
    }

    method text_an (Str $word) {

        return $word =~ /\A[aeiou]/ ? "an $word" : "a $word";
    }
}

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@class Pod::MetaFusion::Renderer
Renderer base class

@method find_closest_named_class
%param $meta Search for a named class in the hierarchy of this meta class object.
Returns the first meta class object in the inheritance hierarchy that is not anonymous.

@method get_package_from_type
%param $type_constraint Any kind of type constraint.
If the passed type constraint is a class or role type this will return the package,
otherwise an undefined value will be returned.

@method meta_from_field
%param $spec The specification to use to fetch the value.
%param $name The name of the field to fetch.
This will fetch a value from the specified field C<$name>, load it as a class and return
its meta object.

@method render
%param $spec The specification to render against.
Renders the documentation and returns it as a string.

@method render_authors_section
Renders the AUTHORS section if one was specified.

@method render_content_field
%param $spec The spec that holds the content to fetch.
%param $field_name The name of the field that holds the content in the spec.
Renders a section via L</render_section> with C<$field_name> as name and the field's value
in the C<$spec> as the content.

@method render_contributors_section
Renders the CONTRIBUTORS section if one was specified.

@method render_description_section
Renders the DESCRIPTION section if one was specified.

@method render_envmarks_section
Currently only renders the ASSUMED VERSIONS section when a C<note_verson> field was specified.

@method render_license_section
Renders the LICENSE section if one was specified.

@method render_list
%param @parts Even numbered list of headers/contents.
Renders a POD list with its arguments.

@method render_section
%param $name Name of the section.
%param $content Section content.
Renders a simple section.

@method render_see_also_section
Renders the SEE ALSO Section if any C<see_also> fields were specified.

@method render_synopsis_section
Renders the SYNOPSIS section if one was specified.

@method render_type_constraint
Renders a type constraint as POD text (not verbatim, it might contain links).

@method section_order
Calculates the section order by the values in L</section_order_map>.

@method text_an
Internal method for text formatting.

@attr report
Holds the report that should be used to collect rendering data.

@attr section_order_map
Holds the sections and their order as numbers.

=end fusion






=head1 NAME

Pod::MetaFusion::Renderer - Renderer base class

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Renderer

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * report (B<required>)

Initial value for the L<report|/"report (required)"> attribute.

=item * section_order (optional)

Initial value for the L<section_order_map|/"section_order_map (optional)"> attribute.

=back

=head2 clear_section_order_map

Clearer for the L<section_order_map|/"section_order_map (optional)"> attribute.

=head2 find_closest_named_class

    ->find_closest_named_class(Object $meta)

=over

=item * Positional Parameters:

=over

=item * Object C<$meta>

Search for a named class in the hierarchy of this meta class object.

=back

=back

Returns the first meta class object in the inheritance hierarchy that is not anonymous.

=head2 get_package_from_type

    ->get_package_from_type(Object $type_constraint)

=over

=item * Positional Parameters:

=over

=item * Object C<$type_constraint>

Any kind of type constraint.

=back

=back

If the passed type constraint is a class or role type this will return the package,
otherwise an undefined value will be returned.

=head2 has_section_order_map

Predicate for the L<section_order_map|/"section_order_map (optional)"> attribute.

=head2 meta_from_field

    ->meta_from_field(Spec $spec, Str $name)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=item * Str C<$name>

Name of the section.

=back

=back

This will fetch a value from the specified field C<$name>, load it as a class and return
its meta object.

=head2 render

    ->render(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the documentation and returns it as a string.

=head2 render_authors_section

    ->render_authors_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the AUTHORS section if one was specified.

=head2 render_content_field

    ->render_content_field(Spec $spec, Str $field_name)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=item * Str C<$field_name>

The name of the field that holds the content in the spec.

=back

=back

Renders a section via L</render_section> with C<$field_name> as name and the field's value
in the C<$spec> as the content.

=head2 render_contributors_section

    ->render_contributors_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the CONTRIBUTORS section if one was specified.

=head2 render_description_section

    ->render_description_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the DESCRIPTION section if one was specified.

=head2 render_envmarks_section

    ->render_envmarks_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Currently only renders the ASSUMED VERSIONS section when a C<note_verson> field was specified.

=head2 render_license_section

    ->render_license_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the LICENSE section if one was specified.

=head2 render_list

    ->render_list(@parts)

=over

=item * Positional Parameters:

=over

=item * C<@parts>

Even numbered list of headers/contents.

=back

=back

Renders a POD list with its arguments.

=head2 render_section

    ->render_section(Str $name, Str $content)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

Name of the section.

=item * Str C<$content>

Section content.

=back

=back

Renders a simple section.

=head2 render_see_also_section

    ->render_see_also_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the SEE ALSO Section if any C<see_also> fields were specified.

=head2 render_synopsis_section

    ->render_synopsis_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

The spec that holds the content to fetch.

=back

=back

Renders the SYNOPSIS section if one was specified.

=head2 render_type_constraint

    ->render_type_constraint(Object $type_constraint, Str :$local_package)

=over

=item * Positional Parameters:

=over

=item * Object C<$type_constraint>

Any kind of type constraint.

=back

=item * Named Parameters:

=over

=item * Str C<:$local_package>

=back

=back

Renders a type constraint as POD text (not verbatim, it might contain links).

=head2 report

Reader for the L<report|/"report (required)"> attribute.

=head2 section_order

    ->section_order()

=over

=back

Calculates the section order by the values in L</section_order_map>.

=head2 section_order_map

Reader for the L<section_order_map|/"section_order_map (optional)"> attribute.

=head2 text_an

    ->text_an(Str $word)

=over

=item * Positional Parameters:

=over

=item * Str C<$word>

=back

=back

Internal method for text formatting.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 report (required)

=over

=item * Type Constraint

L<Pod::MetaFusion::Report>

=item * Constructor Argument

report

=item * Associated Methods

L<report|/report>

=back

Holds the report that should be used to collect rendering data.

=head2 section_order_map (optional)

=over

=item * Type Constraint

HashRef[Int]

=item * Default

Built lazily during runtime.

=item * Constructor Argument

section_order

=item * Associated Methods

L<section_order_map|/section_order_map>, L<has_section_order_map|/has_section_order_map>, L<clear_section_order_map|/clear_section_order_map>

=back

Holds the sections and their order as numbers.

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut
