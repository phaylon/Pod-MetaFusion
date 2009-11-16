use MooseX::Declare;

class Pod::MetaFusion::Module::Spec {

    use MooseX::Types::Moose qw( Object HashRef ArrayRef );

    use aliased 'Pod::Elemental';
    use aliased 'Pod::Elemental::Transformer::Pod5';
    use aliased 'Pod::MetaFusion::Renderer::Class';
    use aliased 'Pod::MetaFusion::Renderer::Role';
    use aliased 'Pod::MetaFusion::Renderer::TypeLibrary';

    my $pod5 = Pod5->new;

    has pod => (
        is          => 'ro',
        isa         => 'Pod::Elemental::Document',
        required    => 1,
    );

    has spec_section => (
        is          => 'ro',
        isa         => 'Pod::Elemental::Element::Pod5::Region',
        required    => 1,
        handles     => {
            section_children => 'children',
        },
    );

    has data => (
        traits      => [qw( Hash )],
        is          => 'ro',
        isa         => HashRef[ArrayRef],
        lazy_build  => 1,
        init_arg    => undef,
        handles     => {
            has_class_field     => [exists => 'class'],
            has_role_field      => [exists => 'role'],
            has_module_field    => [exists => 'module'],
            has_typelib_field   => [exists => 'typelib'],
            get_field           => 'get',
        },
    );

    method spec_content () {

        return sprintf "=begin fusion\n\n%s\n\n=end fusion\n\n", join("\n\n",
            map { s/(?: \A[\n]* | [\n]*\Z )//gx; $_ }
            map { "$_" }
            map { $_->as_pod_string } 
            @{ $self->spec_section->children });

        return $self->spec_section->as_pod_string;

        return join("\n",
            '=begin fusion',
            '',
            $self->spec_section->as_pod_string,
#            (map map { $_->as_pod_string } @{ $self->section_children }),
            '',
            '=end fusion',
        );
    }

    method get_single_field (Str $name, Bool :$optional?) {

        my $fields = $self->get_field($name);

        return
            if $optional and ( not($fields) or @$fields > 1 );

        die "Cannot have more than one or no $name field"
            if not $fields or @$fields > 1;
        
        return $fields->[0];
    }

    method _build_data {

        my $content = join "\n\n", map { $_->as_pod_string } @{ $self->section_children };
        my @lines   = split /\n/, $content;

        my (%data, $latest_content, $latest_section);

        for my $line (@lines) {

            if ($line =~ /\A \@ ([a-z_]+) (?: \s+ (\S+) )? \s* \n? \Z/xism) {
                my ($field, $params) = (lc($1), $2);
                
                push @{ $data{ $field } ||= [] }, [$params, $latest_content = [], $latest_section = {}];
            }
            elsif ($line =~ /\A \% ([a-z_]+) (?: \s+ (.+) )? \s* \n? \Z/xi) {
                my ($field, $content) = (lc($1), $2);

                push @{ $latest_section->{ $field } ||= [] }, $content;
            }
            else {

                push @$latest_content, $line
                    if $latest_content;
            }
        }

        return +{ map {
            my $field = $_;
            $field => [ map {
                my $item = $_;
                [ 
                    $item->[0], 
                    join("\n", @{ $item->[1] }),
                    $item->[2],
                ],
            } @{ $data{ $field } || [] } ];
        } keys %data };
    }

    method renderer_class () {

        if (scalar(grep { $self->$_ } qw( has_class_field has_role_field has_module_field has_typelib_field )) != 1) {
            die "Expected at least one class, role, module or typelib field";
        }

        return  $self->has_class_field      ? Class
              : $self->has_role_field       ? Role
              : $self->has_typelib_field    ? TypeLibrary
              : undef;
    }

    method try_as_new (ClassName $class: Str $pod) {

        my $doc = $pod5->transform_node(Elemental->read_string($pod));

        for my $child (@{ $doc->children }) {
            
            if ($child->isa('Pod::Elemental::Element::Pod5::Region') and $child->format_name eq 'fusion') {

                return $class->new(pod => $doc, spec_section => $child);
            }
        }

        return undef;
    }

    method wrap (Str $pod) {

        return join("\n",
            '=encoding utf-8',
            '',
            $self->spec_content,
            '',
            '',
            '',
            $pod,
        );
    }
}

__END__

=begin fusion

@note_version   Moose
@note_version   Pod::Elemental
@see_also       Pod::Elemental
@license        Pod::MetaFusion

@class Pod::MetaFusion::Module::Spec 
Load and transform fusion specs

@method get_field

    ->get_field(Str $name)

Returns all collected field values for a specific field.

@method get_single_field
%param $name The name of the field to fetch.
%param :$optional Return undef instead of dying when there are no or too many values.
Returns a single collected item.

@method has_class_field
True if a C<class> field was specified.

@method has_module_field
True if a C<module> field was specified-

@method has_role_field
True if a C<role> field was specified.

@method has_typelib_field
True if a C<typelib> field was specified.

@method renderer_class
Returns the correct renderer class depending on the specified fields.

@method spec_content
Recreates the full C<fusion> spec POD section.

@method try_as_new
%param $pod The POD to search for a C<fusion> section.
Returns a new object if a spec was found or undef if not.

@method wrap
%param $pod The newly generated POD that should be inserted instead of the old one.
Returns the full normalized POD section with C<$pod> as the generated, real content.

@attr data
Holds the deparsed data.

@attr pod
The POD document our C<fusion> section is in.

@attr spec_section
Our C<fusion> section in the POD document.

=end fusion






=head1 NAME

Pod::MetaFusion::Module::Spec - Load and transform fusion specs

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Module::Spec

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * pod (B<required>)

Initial value for the L<pod|/"pod (required)"> attribute.

=item * spec_section (B<required>)

Initial value for the L<spec_section|/"spec_section (required)"> attribute.

=back

=head2 clear_data

Clearer for the L<data|/"data (optional)"> attribute.

=head2 data

Reader for the L<data|/"data (optional)"> attribute.

=head2 get_field

Delegation to a generated method in the L<data|/data (optional)> attribute.

    ->get_field(Str $name)

Returns all collected field values for a specific field.

=head2 get_single_field

    ->get_single_field(Str $name, Bool :$optional)

=over

=item * Positional Parameters:

=over

=item * Str C<$name>

The name of the field to fetch.

=back

=item * Named Parameters:

=over

=item * Bool C<:$optional>

Return undef instead of dying when there are no or too many values.

=back

=back

Returns a single collected item.

=head2 has_class_field

Delegation to a generated method in the L<data|/data (optional)> attribute.

True if a C<class> field was specified.

=head2 has_data

Predicate for the L<data|/"data (optional)"> attribute.

=head2 has_module_field

Delegation to a generated method in the L<data|/data (optional)> attribute.

True if a C<module> field was specified-

=head2 has_role_field

Delegation to a generated method in the L<data|/data (optional)> attribute.

True if a C<role> field was specified.

=head2 has_typelib_field

Delegation to a generated method in the L<data|/data (optional)> attribute.

True if a C<typelib> field was specified.

=head2 pod

Reader for the L<pod|/"pod (required)"> attribute.

=head2 renderer_class

    ->renderer_class()

=over

=back

Returns the correct renderer class depending on the specified fields.

=head2 section_children

Delegation to the L<children|Pod::Elemental::Element::Pod5::Region/children> method in the L<spec_section|/spec_section (required)> attribute.

=head2 spec_content

    ->spec_content()

=over

=back

Recreates the full C<fusion> spec POD section.

=head2 spec_section

Reader for the L<spec_section|/"spec_section (required)"> attribute.

=head2 try_as_new

    ->try_as_new(ClassName $class: Str $pod)

=over

=item * Positional Parameters:

=over

=item * Str C<$pod>

The newly generated POD that should be inserted instead of the old one.

=back

=back

Returns a new object if a spec was found or undef if not.

=head2 wrap

    ->wrap(Str $pod)

=over

=item * Positional Parameters:

=over

=item * Str C<$pod>

The newly generated POD that should be inserted instead of the old one.

=back

=back

Returns the full normalized POD section with C<$pod> as the generated, real content.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Module::Spec> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 data (optional)

=over

=item * Type Constraint

HashRef[ArrayRef]

=item * Default

Built lazily during runtime.

=item * Constructor Argument

This attribute can not be directly set at object construction.

=item * Associated Methods

L<data|/data>, L<has_data|/has_data>, L<clear_data|/clear_data>, L<has_typelib_field|/has_typelib_field>, L<has_role_field|/has_role_field>, L<has_module_field|/has_module_field>, L<has_class_field|/has_class_field>, L<get_field|/get_field>

=back

Holds the deparsed data.

=head2 pod (required)

=over

=item * Type Constraint

L<Pod::Elemental::Document>

=item * Constructor Argument

pod

=item * Associated Methods

L<pod|/pod>

=back

The POD document our C<fusion> section is in.

=head2 spec_section (required)

=over

=item * Type Constraint

L<Pod::Elemental::Element::Pod5::Region>

=item * Constructor Argument

spec_section

=item * Associated Methods

L<spec_section|/spec_section>, L<section_children|/section_children>

=back

Our C<fusion> section in the POD document.

=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * Pod::Elemental

Version 0.093000

=item * Moose

Version 0.92

=back

=head1 SEE ALSO

=over

=item * L<Pod::Elemental>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut
