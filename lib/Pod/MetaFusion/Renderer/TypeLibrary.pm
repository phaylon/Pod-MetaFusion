use MooseX::Declare;

class Pod::MetaFusion::Renderer::TypeLibrary
    extends Pod::MetaFusion::Renderer 
    with    Pod::MetaFusion::Renderer::WithName {

    use Scalar::Util                 qw( blessed );
    use Moose::Util::TypeConstraints qw( find_type_constraint );

    use aliased 'Pod::MetaFusion::Module::Spec';

    around _build_section_order_map {

        return {
            %{ $self->$orig },
            types => 100,
        };
    }

    method name_field () { 'typelib' }

    method render_types_section (Spec $spec) {

        my $meta = $self->meta_from_field($spec, $self->name_field)
            or die "Unable to find meta for type library";
        my $lib  = $meta->name;
        my %data = map { ($_->[0], $_->[1]) } @{ $spec->get_field('type') || [] };

        return $self->render_section(types => join "\n",
            map { 
                    my $type = find_type_constraint $lib->get_type($_);
                (
                    sprintf('=head2 %s', $_),
                    '',
                  ( $type->has_parent ? (
                    sprintf('Subtype of %s', $self->render_type_constraint($type->parent, local_package => $lib)),
                    '',
                  ) : () ),
                  ( ($type->has_coercion and @{ $type->coercion->type_coercion_map || [] }) ? (
                    'Available coercions:',
                    '',
                    $self->render_list(
                        map  { ($self->render_type_constraint($_), '') }
                        grep { blessed($_) and $_->isa('Moose::Meta::TypeConstraint') }
                            @{ $type->coercion->type_coercion_map || [] }
                    ),
                  ) : () ),
                  ( $type->isa('Moose::Meta::TypeConstraint::Enum') ? (
                    'Valid values:',
                    '',
                    $self->render_list(
                        map { ( (sprintf 'C<%s>', $_), '' ) }
                            @{ $type->values }
                    ),
                  ) : () ),
                  ( $data{ $_ } ? (
                    $data{ $_ },
                    '',
                  ) : () ),
                );
            } $lib->type_names
        );
    }
}

1;

__END__

=begin fusion

@see_also Pod::MetaFusion
@see_also MooseX::Types
@license  Pod::MetaFusion

@class Pod::MetaFusion::Renderer::TypeLibrary
Render type library documentation

@method name_field
Returns the name of the field that holds the package of the type library. Defaults to C<typelib>.

@method render_types_section
Renders the TYPES section.

=end fusion






=head1 NAME

Pod::MetaFusion::Renderer::TypeLibrary - Render type library documentation

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Renderer::TypeLibrary

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

=item * L<Pod::MetaFusion::Renderer::WithName>

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

Returns the name of the field that holds the package of the type library. Defaults to C<typelib>.

=head2 render_types_section

    ->render_types_section(Spec $spec)

=over

=item * Positional Parameters:

=over

=item * L<Pod::MetaFusion::Module::Spec> C<$spec>

=back

=back

Renders the TYPES section.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Renderer::TypeLibrary> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=item * L<MooseX::Types>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut
