use MooseX::Declare;

class Pod::MetaFusion::Renderer::Class 
    extends Pod::MetaFusion::Renderer 
    with    Pod::MetaFusion::Renderer::WithAttributes
    with    Pod::MetaFusion::Renderer::WithMethods
    with    Pod::MetaFusion::Renderer::WithRoles
    with    Pod::MetaFusion::Renderer::WithInheritance
    with    Pod::MetaFusion::Renderer::WithName {

    method name_field () { 'class' }
}

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@class Pod::MetaFusion::Renderer::Class
Render class documentation

@method name_field
Returns the name of the field that holds the class to introspect. Defaults to C<class>.

=end fusion






=head1 NAME

Pod::MetaFusion::Renderer::Class - Render class documentation

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Renderer::Class

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

=item * L<Pod::MetaFusion::Renderer::WithInheritance>

=item * L<Pod::MetaFusion::Renderer::WithMethods>

=item * L<Pod::MetaFusion::Renderer::WithName>

=item * L<Pod::MetaFusion::Renderer::WithRoles>

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

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

Returns the name of the field that holds the class to introspect. Defaults to C<class>.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::Class> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut