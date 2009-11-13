use MooseX::Declare;

class Pod::MetaFusion::Module::Spec {

    use MooseX::Types::Moose qw( Object HashRef );

    use aliased 'Pod::Elemental';
    use aliased 'Pod::Elemental::Transformer::Pod5';
    use aliased 'Pod::MetaFusion::Renderer::Class';

    my $pod5 = Pod5->new;

    has pod => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
    );

    has spec_section => (
        is          => 'ro',
        isa         => Object,
        required    => 1,
        handles     => {
            section_children => 'children',
        },
    );

    has data => (
        traits      => [qw( Hash )],
        is          => 'ro',
        isa         => HashRef,
        lazy_build  => 1,
        handles     => {
            has_class_field     => [exists => 'class'],
            has_role_field      => [exists => 'role'],
            has_module_field    => [exists => 'module'],
            get_field           => 'get',
        },
    );

    method spec_content {

        return join("\n",
            '=begin fusion',
            '',
            join('', map { $_->as_pod_string } @{ $self->section_children }),
            '',
            '=end fusion',
        );
    }

    method get_single_field (Str $name, Bool :$optional?) {

        my $fields = $self->get_field($name);

        return
            if $optional and not $fields or @$fields > 1;

        die "Cannot have more than one $name field"
            if not $fields or @$fields > 1;
        
        return $fields->[0];
    }

    method _build_data {

        my $content = join '', map { $_->as_pod_string } @{ $self->section_children };
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
                    join('', @{ $item->[1] }),
                    $item->[2],
                ],
            } @{ $data{ $field } || [] } ];
        } keys %data };
    }

    method renderer_class {

        if (scalar(grep { $self->$_ } qw( has_class_field has_role_field has_module_field )) != 1) {
            die "Expected at least one class, role or module field";
        }

        return  $self->has_class_field  ? Class
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
            $self->spec_content,
            '',
            '',
            '',
            $pod,
        );
    }
}
