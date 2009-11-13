use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithName {

    requires qw( name_field );

    use List::AllUtils qw( insert_after_string );

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            name => -999,
        };
    }

    method render_name_section (Object $spec) {

        my $field = $spec->get_single_field($self->name_field);

        my ($value, $content) = @$field;

        return $self->render_section(
            name => join(' - ', $value || (), $content || ()),
        );
    }
}
