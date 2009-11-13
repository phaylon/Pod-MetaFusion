use MooseX::Declare;

class Pod::MetaFusion::Script with MooseX::Getopt {

    use MooseX::Types::Moose        qw( HashRef ArrayRef Str );
    use MooseX::Types::Path::Class  qw( File Dir );
    use Pod::MetaFusion::Types      qw( ExistingItem ExistingFile );

    use aliased 'Pod::MetaFusion';

    has target => (
        is          => 'ro',
        isa         => ExistingItem,
        coerce      => 1,
        required    => 1,
        handles     => {
            target_is_dir   => 'is_dir',
        },
    );

    has settings_file => (
        is          => 'ro',
        isa         => ExistingFile,
        required    => 1,
        coerce      => 1,
        init_arg    => 'settings',
    );

    has lib_paths => (
        traits      => [qw( Array )],
        is          => 'ro',
        isa         => ArrayRef[Str],
        default     => sub { [] },
        required    => 1,
        init_arg    => 'lib',
        handles     => {
            _lib_path_list => 'elements',
        },
    );

    method run () {

        local @INC = ($self->_lib_path_list, @INC);

        my $fusion = MetaFusion->new_with_config(configfile => $self->settings_file);
        my $report = $fusion->fuse($self->target);
        
        $report->done;
        $report->display($self->target);
    }
}

