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
                grep { $_->original_package_name eq $meta->name } 
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
            ($a->isa('Moose::Meta::Method::Constructor') or $a->name eq 'new')  ? -1
          : ($b->isa('Moose::Meta::Method::Constructor') or $b->name eq 'new')  ? 1
          : ($a->name eq 'meta')                                                ? 1
          : ($b->name eq 'meta')                                                ? -1
          : $a->name cmp $b->name
        } grep {
            $_->name !~ /\A_/
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

        elsif ($method->isa('Moose::Meta::Method::Constructor') or $method->name eq 'new') {

            return(
                'Object constructor accepting the following parameters;',
                '',
                $self->render_list(
                    map  { (
                            sprintf(
                                '%s (%s)',
                                $_->init_arg,
                                ( $_->is_required and not( $_->default or $_->builder or $_->is_lazy_build ) )
                                    ? 'B<required>' 
                                    : 'optional'
                            ), 
                            sprintf(
                                'Initial value for the%s L<%s|%s/"%s"> attribute.',
                              ( ($_->associated_class->name eq $meta->name) ? '' : ' inherited' ),
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

        elsif ($method->isa('Moose::Meta::Method::Delegation')) {

            my $attr     = $method->associated_attribute;
            my $delegate = $method->delegate_to_method;
            my $class    = $attr->type_constraint ? $self->get_package_from_type($attr->type_constraint) : undef;

            return(
                ucfirst(sprintf(
                    '%sdelegation to %s method in the L<%s|/%s> attribute.',
                    ( @{ $method->curried_arguments || [] } ? 'curried ' : '' ),
                    ( ($delegate !~ /\A_/) 
                        ? ( $class
                            ? sprintf('the L<%s|%s/%s>', $delegate, $class, $delegate)
                            : ( (ref($delegate) eq 'CODE')
                                ? 'a generated'
                                : sprintf('the C<%s>', $delegate)
                            )
                          )
                        : 'a private'
                    ),
                    $attr->name,
                    $self->render_attribute_name($attr),
                )),
            );
        }

        elsif (any { $method->name eq $_ } qw( BUILD DESTROY DEMOLISH )) {

            return;
        }

        elsif ($method->isa('MooseX::Method::Signatures::Meta::Method')) {

            my $sig = $method->parsed_signature;
            my $ret = $method->has_return_signature && $method->_return_type_constraint;

            my $render_param = sub {
                my $param = shift;
                return join ' ',
                  ( $param->type_constraints ? $self->render_type_constraint($param->type_constraints->tc) : () ),
                    sprintf('C<%s>', $param->_stringify_variable_name);
            };

            my @positional = $sig->has_positional_params ? (
                map  { ($render_param->($_->[1]), $map->{param}{ $_->[0] } || '') }
                map  { [$_->_stringify_variable_name, $_] }
                    $sig->positional_params
            ) : ();

            my @named = $sig->has_named_params ? (
                map  { ($render_param->($_->[1]), $map->{param}{ $_->[0] } || '') }
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
                  ( $ret ? (
                    'Returns' => $self->render_type_constraint($ret),
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

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@role Pod::MetaFusion::Renderer::WithMethods
Render method documentation

@requires name_field
See L<Pod::MetaFusion::Renderer::WithName>

@method render_methods_section
Renders the METHODS section.

=end fusion



=head1 NAME

Pod::MetaFusion::Renderer::WithMethods - Render method documentation

=head1 REQUIRED METHODS

=head2 name_field

See L<Pod::MetaFusion::Renderer::WithName>

=head1 APPLIED ROLES

=over

=item * L<Pod::MetaFusion::Renderer::WithAttributes>

=item * L<Pod::MetaFusion::Renderer::WithName>

=back

=head1 METHODS

=head2 render_methods_section

    ->render_methods_section(Object $spec)

=over

=item * Positional Parameters:

=over

=item * Object C<$spec>

=back

=back

Renders the METHODS section.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::WithMethods> as an instance of L<Moose::Meta::Role>

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut