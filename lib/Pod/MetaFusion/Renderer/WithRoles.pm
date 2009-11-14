use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithRoles with Pod::MetaFusion::Renderer::WithName {

    use List::AllUtils qw( uniq );

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            roles => -45,
        };
    }

    method render_roles_section (Object $spec) {
        
        my $meta  = $self->meta_from_field($spec, $self->name_field);
        my @roles = 
            map  { (split /\|/, $_) } 
            grep { not($meta->isa('Moose::Meta::Role')) or $meta->name ne $_ } 
            map  { $_->name } 
                $meta->calculate_all_roles;

        return unless @roles;

        return $self->render_section(
            'applied roles',
            $self->render_list(
                map { (sprintf('L<%s>', $_), '') } uniq sort @roles
            ),
        );
    }
}

1;

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@role Pod::MetaFusion::Renderer::WithRoles
Render documentation about consumed roles

@method render_roles_section
Renders the APPLIED ROLES section, if any roles were consumed.

@requires name_field
See L<Pod::MetaFusion::Renderer::WithName>.

=end fusion



=head1 NAME

Pod::MetaFusion::Renderer::WithRoles - Render documentation about consumed roles

=head1 REQUIRED METHODS

=head2 name_field

See L<Pod::MetaFusion::Renderer::WithName>.

=head1 APPLIED ROLES

=over

=item * L<Pod::MetaFusion::Renderer::WithName>

=back

=head1 METHODS

=head2 render_roles_section

    ->render_roles_section(Object $spec)

=over

=item * Positional Parameters:

=over

=item * Object C<$spec>

=back

=back

Renders the APPLIED ROLES section, if any roles were consumed.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::WithRoles> as an instance of L<Moose::Meta::Role>

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut