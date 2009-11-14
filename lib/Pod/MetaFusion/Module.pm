use MooseX::Declare;

class Pod::MetaFusion::Module extends PPI::Transform {
    use MooseX::NonMoose;
    use CLASS;

    use Path::Class                 qw( file );
    use MooseX::Types::Moose        qw( HashRef );
    use MooseX::Types::Structured   qw( Dict Optional );

    use aliased 'PPI::Find';
    use aliased 'Pod::MetaFusion::Report';
    use aliased 'Pod::MetaFusion::Module::Spec';

    has fusion_report => (
        is          => 'rw',
        isa         => Report,
        required    => 1,
        default     => sub { Report->new },
        lazy        => 1,
        handles     => [qw( add_skipped add_rebuilt )],
    );

    has pod_finder => (
        is          => 'ro',
        isa         => Find,
        lazy_build  => 1,
        init_arg    => undef,
        handles     => {
            find_pod_in => 'in',
        },
    );

    has render_config => (
        traits      => [qw( Hash )],
        is          => 'ro',
        isa         => Dict[map { ($_ => Optional[HashRef]) } qw( Class Role Module )],
        required    => 1,
        default     => sub { {} },
        init_arg    => 'render',
        handles     => {
            _render_config_list => 'elements',
        },
    );

    method document (Object $doc) {

        for my $pod ($self->find_pod_in($doc)) {
            
            if (my $fusion_spec = Spec->try_as_new($pod->content)) {
#                warn "SPEC $fusion_spec";
#                $fusion_spec->data;
                my $r_class  = $fusion_spec->renderer_class;
                $r_class =~ /::([a-z]+)\Z/i;
                my $r_type   = $1;
                my $rendered = $r_class->new($self->_render_config_list, report => $self->fusion_report)->render($fusion_spec);
                my $wrapped  = $fusion_spec->wrap($rendered);
                $pod->set_content($wrapped);
#                warn "WRITING $wrapped";
#                warn "RENDERED $rendered";
                $self->add_rebuilt(file $doc->filename);
                return 1;
            }
        }

        $self->add_skipped(file $doc->filename);
        return 0;
    }

    method _build_pod_finder {

        return Find->new(sub {
            my ($item, $top) = @_;
            return $item->isa('PPI::Token::Pod') ? 1 : 0;
        });
    }

    CLASS->meta->make_immutable(inline_constructor => 0);
}

1;

__END__

=begin fusion

@note_version Moose
@note_version PPI

@see_also Pod::MetaFusion
@see_also PPI::Transform
@see_also PPI

@license Pod::MetaFusion

@class Pod::MetaFusion::Module
Handle module transformations

@attr fusion_report
The report that is used to collect information during the fuse.

@attr pod_finder
Used to find POD sections to transform.

@attr render_config
The configuration for the renderers.

@method document
%param $doc A L<PPI::Document>.

See L<PPI::Transform/document>.

=end fusion



=head1 NAME

Pod::MetaFusion::Module - Handle module transformations

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Module

=over 2

=item *

L<PPI::Transform>

=over 2

=item *

L<Moose::Object>

=back

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters;

=over

=item * fusion_report (optional)

Initial value for the L<fusion_report|/"fusion_report (required)"> attribute.

=item * render (optional)

Initial value for the L<render_config|/"render_config (required)"> attribute.

=back

=head2 add_rebuilt

Delegation to the L<add_rebuilt|Pod::MetaFusion::Report/add_rebuilt> method in the L<fusion_report|/fusion_report (required)> attribute.

=head2 add_skipped

Delegation to the L<add_skipped|Pod::MetaFusion::Report/add_skipped> method in the L<fusion_report|/fusion_report (required)> attribute.

=head2 clear_pod_finder

Clearer for the L<pod_finder|/"pod_finder (optional)"> attribute.

=head2 document

    ->document(Object $doc)

=over

=item * Positional Parameters:

=over

=item * Object C<$doc>

A L<PPI::Document>.

=back

=back

See L<PPI::Transform/document>.

=head2 find_pod_in

Delegation to the L<in|PPI::Find/in> method in the L<pod_finder|/pod_finder (optional)> attribute.

=head2 fusion_report

Accessor for the L<fusion_report|/"fusion_report (required)"> attribute.

=head2 has_pod_finder

Predicate for the L<pod_finder|/"pod_finder (optional)"> attribute.

=head2 pod_finder

Reader for the L<pod_finder|/"pod_finder (optional)"> attribute.

=head2 render_config

Reader for the L<render_config|/"render_config (required)"> attribute.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Module> as an instance of L<Class::MOP::Class::Immutable::Class::MOP::Class::__ANON__::SERIAL::5>

=head1 ATTRIBUTES

=head2 fusion_report (required)

=over

=item * Type Constraint

L<Pod::MetaFusion::Report>

=item * Default

Built lazily during runtime.

=item * Constructor Argument

fusion_report

=item * Associated Methods

L<fusion_report|/fusion_report>, L<add_rebuilt|/add_rebuilt>, L<add_skipped|/add_skipped>

=back

The report that is used to collect information during the fuse.

=head2 pod_finder (optional)

=over

=item * Type Constraint

PPI::Find

=item * Default

Built lazily during runtime.

=item * Constructor Argument

This attribute can not be directly set at object construction.

=item * Associated Methods

L<pod_finder|/pod_finder>, L<has_pod_finder|/has_pod_finder>, L<clear_pod_finder|/clear_pod_finder>, L<find_pod_in|/find_pod_in>

=back

Used to find POD sections to transform.

=head2 render_config (required)

=over

=item * Type Constraint

L<Dict|MooseX::Types::Structured/Dict>[Class,L<Optional|MooseX::Types::Structured/Optional>[HashRef],Role,L<Optional|MooseX::Types::Structured/Optional>[HashRef],Module,L<Optional|MooseX::Types::Structured/Optional>[HashRef]]

=item * Default

Built during runtime.

=item * Constructor Argument

render

=item * Associated Methods

L<render_config|/render_config>

=back

The configuration for the renderers.

=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * Moose

Version 0.92

=item * PPI

Version 1.206

=back

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=item * L<PPI::Transform>

=item * L<PPI>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut