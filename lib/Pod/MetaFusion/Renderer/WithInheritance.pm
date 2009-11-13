use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithInheritance {

    use List::AllUtils  qw( insert_after_string );
    use Moose::Util     qw( find_meta );

    requires qw( name_field );

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            inheritance => -50,
        };
    }

    method render_inheritance_section (Object $spec) {

        my $field = $spec->get_single_field($self->name_field);
        my $class = $field->[0];

#        require $file;
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
