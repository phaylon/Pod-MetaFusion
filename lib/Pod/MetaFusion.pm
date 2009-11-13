use MooseX::Declare;

class Pod::MetaFusion with MooseX::SimpleConfig {

    use MooseX::Types::Moose    qw( HashRef );
    use Pod::MetaFusion::Types  qw( ExistingItem ExistingFile ExistingDir );

    use aliased 'Pod::MetaFusion::Module';

    our $VERSION = 0.01;

    has module_config => (
        traits      => [qw( Hash )],
        is          => 'ro',
        isa         => HashRef,
        init_arg    => 'modules',
        required    => 1,
        default     => sub { +{} },
        handles     => {
            _module_config_list => 'elements',
        },
    );

    method fuse (ExistingItem $target) {

        return $self->_fuse_dir($target) if $target->is_dir;

        my $transform = Module->new($self->_module_config_list);
        $transform->file($target->stringify);

        return $transform->fusion_report;
    }

    method _fuse_dir (ExistingDir $target) {

        $target->recurse(callback => sub {
            my $object = shift;

            if (not($object->is_dir) and $object =~ /\.pm\Z/) {
                $self->fuse($object);
            }
        });
    }
}

