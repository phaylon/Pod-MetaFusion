use MooseX::Declare;

role Pod::MetaFusion::Renderer::WithAttributes with Pod::MetaFusion::Renderer::WithName {

    use List::AllUtils  qw( part );


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
            map  { $meta->get_attribute($_) }
                $meta->get_attribute_list;

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
            map { 
                my @methods = @{ $_->associated_methods };
                
              (
                sprintf('=head2 %s', $self->render_attribute_name($_)),
                '',
              ( $_->has_documentation ? (
                $_->documentation,
                '',
              ) : () ),
                $self->render_list(
                    ($_->type_constraint    ? ('Type Constraint'    => $self->render_type_constraint($_->type_constraint))  : ()),
                    ($class_label           ? ($class_label         => sprintf('L<%s>', $_->associated_class->name))        : ()),
                    ( (defined($_->default) or defined($_->builder) or $_->is_lazy_build) ? (
                        Default => (
                            (defined($_->builder) or $_->is_lazy_build or ( defined($_->default) and ref($_->default) )) ? (
                                sprintf('Built%s during runtime.',
                                    ($_->is_lazy or $_->is_lazy_build) ? ' lazily' : ''
                                ),
                            ) : sprintf('C<%s>', $_->default)
                        ),
                    ) : ()),
                    'Constructor Argument' => (
                        defined($_->init_arg)
                        ? $_->init_arg
                        : 'This attribute can not be set in the constructor.'
                    ),
                    ( @methods ? (
                        'Associated Methods' => join(', ', map {
                            sprintf 'L<%s|/%s>', $_->name, $_->name;
                        } grep { $_->name !~ /\A_/ } @methods),
                    ) : () ),
                ),
              ( exists($attr->{ $_->name }) ? (
                $attr->{ $_->name }{content},
                '',
              ) : () ),
            ) } sort { $a->name cmp $b->name } @$attrs
        );
    }
}

1;

__END__

=begin fusion

@see_also Pod::MetaFusion
@license  Pod::MetaFusion

@role Pod::MetaFusion::Renderer::WithAttributes
Render attribute documentation

@requires name_field
See L<Pod::MetaFusion::Renderer::WithName>.

@method inflate_attr_spec
Transforms the attribute specification into a more usable format.

@method render_attribute_name
%param $attr A L<Moose::Meta::Attribute>.
Renders the name of an attribute including a note whether its optional or required.

@method render_attribute_section
Renders the ATTRIBUTES section.

=end fusion



=head1 NAME

Pod::MetaFusion::Renderer::WithAttributes - Render attribute documentation

=head1 REQUIRED METHODS

=head2 name_field

See L<Pod::MetaFusion::Renderer::WithName>.

=head1 APPLIED ROLES

=over

=item * L<Pod::MetaFusion::Renderer::WithName>

=back

=head1 METHODS

=head2 inflate_attr_spec

    ->inflate_attr_spec(Object $spec)

=over

=item * Positional Parameters:

=over

=item * Object $spec

=back

=back

Transforms the attribute specification into a more usable format.

=head2 render_attribute_name

    ->render_attribute_name(Object $attr)

=over

=item * Positional Parameters:

=over

=item * Object $attr

A L<Moose::Meta::Attribute>.

=back

=back

Renders the name of an attribute including a note whether its optional or required.

=head2 render_attributes_section

    ->render_attributes_section(Object $spec)

=over

=item * Positional Parameters:

=over

=item * Object $spec

=back

=back

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::WithAttributes> as an instance of L<Moose::Meta::Role>

=head1 SEE ALSO

=over

=item * Pod::MetaFusion

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut