use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithMethods with Pod::MetaFusion::Renderer::WithAttributes {

    use List::AllUtils  qw( any );
    use Moose::Util     qw( find_meta );

    requires qw( name_field );

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            methods => 90,
        };
    }

    method render_methods_section (Object $spec) {
        
        my $meta    = $self->meta_from_field($spec, $self->name_field);
        my @methods = 
                grep { $_->package_name eq $meta->name } 
                map  { $meta->get_method($_) } 
                    $meta->get_method_list
            or return;

        return join("\n",
            '=head1 METHODS',
            '',
            $self->_render_methods($spec, \@methods, $meta),
        );
    }

    method _inflate_method_spec (Object $spec) {

        my $method_spec = $spec->get_field('method')
            or return {};

        my %map;
        my %param_map;

        for my $method (@$method_spec) {
            my ($name, $content, $attrs) = @$method;
            $attrs ||= {};

            if ($attrs->{param}) {
                
                for my $param (@{ $attrs->{param} }) {
                    my ($name, $text) = split / /, $param, 2;
                    $param_map{ $name } = $text;
                }
            }

            $map{ $name } = { content => $content, param => \%param_map };
        }

        return \%map;
    }

    method _render_methods (Object $spec, ArrayRef[Object] $methods, Object $meta) {

        my $content_map = $self->_inflate_method_spec($spec);

        return map {
            my @data = $self->_render_method_data($content_map->{ $_->name } || {}, $_, $meta);

            ( @data ? (
                sprintf('=head2 %s', $_->name),
                '',
                @data,
                '',
              ( $content_map->{ $_->name } ? (
                $content_map->{ $_->name }{content},
                '',
              ) : () ),
            ) : () );
        } sort {
            $a->isa('Moose::Meta::Method::Constructor') ? -1
          : $b->isa('Moose::Meta::Method::Constructor') ? 1
          : ($a->name eq 'meta')                        ? 1
          : ($b->name eq 'meta')                        ? -1
          : $a->name cmp $b->name
        } @$methods;
    }

    method _render_method_data (HashRef $map, Object $method, Object $meta) {

        if ($method->name eq 'meta') {

            return sprintf 'Returns the meta object for C<%s> as an instance of L<%s>',
                $meta->name,
                find_meta($self->find_closest_named_class($meta))->name;

        }

        elsif ($method->isa('Moose::Meta::Method::Accessor')) {

            my $attr = $method->associated_attribute;

            return(
                sprintf('%s for the L<%s|/"%s"> attribute.',
                    ucfirst($method->accessor_type),
                    $attr->name,
                    $self->render_attribute_name($attr),
                ),
            );
        }

        elsif ($method->isa('Moose::Meta::Method::Constructor')) {

            return(
                'Object constructor accepting the following parameters;',
                '',
                $self->render_list(
                    map  { (
                            sprintf(
                                '%s (%s)',
                                $_->init_arg,
                                ( $_->is_required and not( $_->default or $_->builder ) )
                                    ? 'B<required>' 
                                    : 'optional'
                            ), 
                            sprintf(
                                'Initial value for the L<%s|%s/"%s"> attribute.',
                                $_->name,
                              ( ($_->associated_class->name eq $meta->name) ? '' : $_->associated_class->name ),
                                $self->render_attribute_name($_),
                            )),
                         }
                    grep { defined $_->init_arg }
                    sort { $a->name cmp $b->name }
                        $meta->get_all_attributes
                ),
            );
        }

        elsif (any { $method->name eq $_ } qw( BUILD DESTROY DEMOLISH )) {

            return;
        }

        elsif ($method->isa('MooseX::Method::Signatures::Meta::Method')) {

            my $sig = $method->parsed_signature;

            my @positional = $sig->has_positional_params ? (
                map  { ($_->[1]->to_string, $map->{param}{ $_->[0] } || '') }
                map  { [$_->_stringify_variable_name, $_] }
                    $sig->positional_params
            ) : ();

            my @named = $sig->has_named_params ? (
                map  { ($_->[1]->to_string, $map->{param}{ $_->[0] } || '') }
                sort { $a->[0] cmp $b->[0] }
                map  { [$_->_stringify_variable_name, $_] }
                    $sig->named_params
            ) : ();

            return 
                sprintf('    ->%s%s', $method->name, $sig->to_string),
                '',
                $self->render_list(
                  ( @positional ? (
                    'Positional Parameters:' => $self->render_list(@positional),
                  ) : () ),
                  ( @named ? (
                    'Named Parameters:' => $self->render_list(@named),
                  ) : () ),
                );
        }

        else {

            return 'Undocumented method.', ''
                unless $map->{content};
        }
    }
}

1;
