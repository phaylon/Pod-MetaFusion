use MooseX::Declare;

class Pod::MetaFusion::Renderer {

    use MooseX::Types::Moose qw( Object HashRef );
    use List::AllUtils       qw( uniq );
    use Moose::Util          qw( find_meta );

    has report => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
    );

    has section_order_map => (
        is          => 'ro',
        isa         => HashRef,
        lazy_build  => 1,
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

    method section_order {

        my $map = $self->section_order_map;

        return sort { $map->{ $a } <=> $map->{ $b } } keys %$map;
    }

    method meta_from_field (Object $spec, Str $name) {

        my $field = $spec->get_single_field($self->name_field);
        my $class = $field->[0];

        Class::MOP::load_class($class);
        return find_meta $class;
    }

    method render (Object $spec) {

        my @sections;
        
        for my $section (uniq $self->section_order) {

            if (my $method = $self->can("render_${section}_section")) {
                push @sections, $self->$method($spec);
            }
        }

        return join "\n", @sections, '', '=cut';
    }

    method render_type_constraint (Object $tc) {

        my $name = $tc->name;

        if ($name =~ /\A ([a-z0-9_:]+) (.*) \Z /xi) {
            my $found = $1;
            my $rest  = $2;

            if ($tc->isa('Moose::Meta::TypeConstraint::Class')) {
                return sprintf 'L<%s|%s>%s', $found, $tc->class, $rest;
            }

            if ($found =~ /::/) {

                my @parts = split /::/, $found;
                my $type  = pop @parts;
                my $lib   = join '::', @parts;
                return sprintf 'L<%s::%s|%s/%s>%s', $lib, $type, $lib, $type, $rest;
            }
        }

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
            sprintf('=head1 %s', uc $name),
            '',
            $content,
            '',
        );
    }

    method render_content_field (Object $spec, Str $field_name) {

        my $field = $spec->get_single_field($field_name, optional => 1)
            or return;

        return $self->render_section($field_name => $field->[1]);
    }

    method render_description_section (Object $spec) {

        return $self->render_content_field($spec, 'description');
    }

    method render_synopsis_section (Object $spec) {

        return $self->render_content_field($spec, 'synopsis');
    }

    method render_authors_section (Object $spec) {

        return $self->render_content_field($spec, 'authors');
    }

    method render_contributors_section (Object $spec) {

        return $self->render_content_field($spec, 'contributors');
    }

    method render_see_also_section (Object $spec) {

        my $see = $spec->get_field('see_also')
            or return;

        my @found;
        for my $link (@$see) {
            my ($target, $text) = @$link;

            push @found, $target, $text;
        }

        return unless @found;
        return $self->render_section('see also', $self->render_list(@found));
    }

    method render_license_section (Object $spec) {

        my $license = $spec->get_single_field('license')
            or return;

        my ($instead, $content) = @$license;

        return $self->render_section(
            'license and copyright',
            join("\n",
              ( $instead ? (
                    sprintf('See L<%s> for information about license and copyright', $instead),
                    '',
              ) : () ),
                $content,
            ),
        );
    }

    method render_envmarks_section (Object $spec) {

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

        for my $isa (map { find_meta $_ } $meta->linearized_isa) {

            return $isa
                unless $isa->is_anon_class;
        }
    }

    method text_an (Str $word) {

        return $word =~ /\A[aeiou]/ ? "an $word" : "a $word";
    }
}
