use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithName {

    requires qw( name_field );

    use List::AllUtils qw( insert_after_string );
    use aliased 'Pod::MetaFusion::Module::Spec';

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            name => -999,
        };
    }

    method render_name_section (Spec $spec) {

        my $field = $spec->get_single_field($self->name_field);

        my ($value, $content) = @$field;
        Class::MOP::load_class($value);
        my $version = $value->VERSION;

        return(
            $self->render_section(
                name => join(' - ', $value || (), $content || ()),
            ),
            $version ? $self->render_section(
                version => $version,
            ) : (),
        );
    }
}

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@role Pod::MetaFusion::Renderer::WithName
Render name and version information

@requires name_field
Has to return the name of the field that holds the class that should be introspected.

@method render_name_section
Renders the NAME section.

=end fusion






=head1 NAME

Pod::MetaFusion::Renderer::WithName - Render name and version information

=head1 REQUIRED METHODS

=head2 name_field

Has to return the name of the field that holds the class that should be introspected.

=head1 METHODS

=head2 render_name_section

    ->render_name_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

=back

=back

Renders the NAME section.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::WithName> as an instance of L<Moose::Meta::Role>

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut