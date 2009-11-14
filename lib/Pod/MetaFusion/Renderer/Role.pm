use MooseX::Declare;

class Pod::MetaFusion::Renderer::Role
    extends Pod::MetaFusion::Renderer 
    with    Pod::MetaFusion::Renderer::WithAttributes
    with    Pod::MetaFusion::Renderer::WithMethods
    with    Pod::MetaFusion::Renderer::WithRoles
    with    Pod::MetaFusion::Renderer::WithName {

    use aliased 'Pod::MetaFusion::Module::Spec';

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            requires => -47,
        };
    }

    method name_field () { 'role' }

    method _render_role_section_part (Spec $spec, Str $name, Str $field, Str $method) {
        
        my $data    = $spec->get_field($field);
        my @methods = $self->meta_from_field($spec, $self->name_field)->$method;
        my %attrs   = map { ($_->[0], $_->[1]) } @$data;

        return $self->render_section($name, join "\n",
            map { (
                '=head2 ' . $_,
                '',
              ( $attrs{ $_ } ? (
                $attrs{ $_ },
                '',
              ) : () ),
            ) } @methods
        );
    }

    method render_requires_section (Spec $spec) {
        
        return $self->_render_role_section_part($spec, 'required methods', 'requires', 'get_required_method_list');
    }
}

__END__

=begin fusion

@see_also Pod::NetaFusion
@license  Pod::MetaFusion

@class Pod::MetaFusion::Renderer::Role
Render role documentation

@method name_field
Returns the name of the field that holds the class that should be introspected. Defaults to C<role>.

@method render_requires_section
Renders the REQUIRED METHODS section.

=end fusion



=head1 NAME

Pod::MetaFusion::Renderer::Role - Render role documentation

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Renderer::Role

=over 2

=item *

L<Pod::MetaFusion::Renderer>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 APPLIED ROLES

=over

=item * L<Pod::MetaFusion::Renderer::WithAttributes>

=item * L<Pod::MetaFusion::Renderer::WithMethods>

=item * L<Pod::MetaFusion::Renderer::WithName>

=item * L<Pod::MetaFusion::Renderer::WithRoles>

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters;

=over

=item * report (B<required>)

Initial value for the inherited L<report|Pod::MetaFusion::Renderer/"report (required)"> attribute.

=item * section_order (optional)

Initial value for the inherited L<section_order_map|Pod::MetaFusion::Renderer/"section_order_map (optional)"> attribute.

=back

=head2 name_field

    ->name_field()

=over

=back

Returns the name of the field that holds the class that should be introspected. Defaults to C<role>.

=head2 render_requires_section

    ->render_requires_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> $spec

=back

=back

Renders the REQUIRED METHODS section.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::Role> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 SEE ALSO

=over

=item * Pod::NetaFusion

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut