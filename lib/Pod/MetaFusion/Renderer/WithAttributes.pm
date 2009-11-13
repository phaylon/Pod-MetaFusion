use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithAttributes {

    use List::AllUtils  qw( part );

    requires qw( name_field );


    around _build_section_order_map {

        return {
            %{ $self->$orig },
            attributes => 100,
        };
    }

    method inflate_attr_spec (Object $spec) {

        my $fields = $spec->get_field('attr')
            or return {};

        my %map;

        for my $field (@$fields) {
            my ($attr, $content) = @$field;

            my ($name, @parts) = split /\s+/, $attr;

            $map{ $name } = { content => $content };
        }

        return \%map;
    }

    method render_attribute_name (Object $attr) {

        return sprintf '%s (%s)',
            $attr->name,
            $attr->is_required ? 'required' : 'optional';
    }

    method render_attributes_section (Object $spec) {

        my $attr = $self->inflate_attr_spec($spec);
        my $meta = $self->meta_from_field($spec, $self->name_field);

        my ($original, $inherited) = 
            part { ($_->associated_class->name eq $meta->name) ? 0 : 1 } 
            grep { $_->name !~ /^_/ }
                $meta->get_all_attributes;

        return unless $original or $inherited;

        return join("\n",
          ( $original ? (
            '=head1 ATTRIBUTES',
            '',
            $self->_render_attributes($attr, $original),
            '',
          ) : () ),
#          ( $inherited ? (
#            '=head1 INHERITED ATTRIBUTES',
#            '',
#            $self->_render_attributes($attr, $inherited, class_label => 'Inherited from'),
#            '',
#          ) : () ),
        );
    }

    method _render_attributes (HashRef $attr, ArrayRef[Object] $attrs, Str :$class_label?) {

        return join("\n",
            map { (
                sprintf('=head2 %s', $self->render_attribute_name($_)),
                '',
              ( $_->has_documentation ? (
                $_->documentation,
                '',
              ) : () ),
                $self->render_list(
                    ($_->type_constraint    ? ('Type Constraint'    => $self->render_type_constraint($_->type_constraint))  : ()),
                    ($class_label           ? ($class_label         => sprintf('L<%s>', $_->associated_class->name))        : ()),
                ),
              ( exists($attr->{ $_->name }) ? (
                $attr->{ $_->name }{content},
                '',
              ) : () ),
            ) } sort { $a->name cmp $b->name } @$attrs
        );
    }
}
