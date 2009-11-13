use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithRoles {

    requires qw( name_field );

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            roles => -45,
        };
    }

    method render_roles_section (Object $spec) {
        
        my $meta = $self->meta_from_field($spec, $self->name_field);

        return $self->render_section(
            'applied roles',
            $self->render_list(
                map { (sprintf('L<%s>', $_->name), '') } @{ $meta->roles }
            ),
        );
    }
}
