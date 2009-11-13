use MooseX::Declare;

class Pod::MetaFusion::Module extends PPI::Transform {
    use MooseX::NonMoose;
    use CLASS;

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
    );

    has pod_finder => (
        is          => 'ro',
        isa         => Find,
        lazy_build  => 1,
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
                warn "WRITING $wrapped";
#                warn "RENDERED $rendered";
                return 1;
            }
        }

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
