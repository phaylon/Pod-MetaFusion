use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithInheritance with Pod::MetaFusion::Renderer::WithName {

    use Moose::Util     qw( find_meta );

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            inheritance => -50,
        };
    }

    method render_inheritance_section (Object $spec) {

        my $field = $spec->get_single_field($self->name_field);
        my $class = $field->[0];

        Class::MOP::load_class($class);
        my $meta = find_meta $class;

        my $render;
        $render = sub {
            return unless @_;
            my ($class, @rest) = @_;

            return join("\n",
                '=over 2',
                  '',
                  '=item *',
                  '',
                  sprintf('L<%s>', $class),
                  '',
                    $render->(@rest),
                  '',
                '=back',
            );
        };
        my $render_top = sub {
            my ($top, @isa) = @_;

            return join("\n",
                '=over 2',
                  '',
                  '=item *',
                  '',
                  $top,
                  '',
                    $render->(@isa),
                  '',
                '=back',
            );
        };

        my @isa = $meta->linearized_isa;
        return $self->render_section(inheritance => $render_top->(@isa));
    }
}

1;

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@role Pod::MetaFusion::Renderer::WithInheritance
Render inheritance documentation

@requires name_field
See L<Pod::MetaFusion::Renderer::WithName>.

@method render_inheritance_section
Renders the INHERITANCE section.

=end fusion



=head1 NAME

Pod::MetaFusion::Renderer::WithInheritance - Render inheritance documentation

=head1 REQUIRED METHODS

=head2 name_field

See L<Pod::MetaFusion::Renderer::WithName>.

=head1 APPLIED ROLES

=over

=item * L<Pod::MetaFusion::Renderer::WithName>

=back

=head1 METHODS

=head2 render_inheritance_section

    ->render_inheritance_section(Object $spec)

=over

=item * Positional Parameters:

=over

=item * Object C<$spec>

=back

=back

Renders the INHERITANCE section.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::WithInheritance> as an instance of L<Moose::Meta::Role>

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut