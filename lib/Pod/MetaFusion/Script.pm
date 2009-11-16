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

        my $fusion = $self->settings_file 
            ? MetaFusion->new_with_config(configfile => $self->settings_file)
            : MetaFusion->new;
        my $report = $fusion->fuse($self->target);
        
        $report->done;
        $report->display($self->target);
    }
}

1;

__END__

=begin fusion

@see_also       Pod::MetaFusion
@see_also       MooseX::Getopt
@note_version   MooseX::Getopt
@license        Pod::MetaFusion

@class Pod::MetaFusion::Script
Command-line fuse functionality.

@method run
Runs the script.

@attr lib_paths
Paths to search for modules to load.

@attr settings_file
An optional settings file.

@attr target
The target that should be fused. Can be either a directory to scan or a single file.

=end fusion






=head1 NAME

Pod::MetaFusion::Script - Command-line fuse functionality.

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Script

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<MooseX::Getopt>

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * ARGV (optional)

Initial value for the L<ARGV|/"ARGV (optional)"> attribute.

=item * extra_argv (optional)

Initial value for the L<extra_argv|/"extra_argv (optional)"> attribute.

=item * lib (optional)

Initial value for the L<lib_paths|/"lib_paths (required)"> attribute.

=item * settings (optional)

Initial value for the L<settings_file|/"settings_file (optional)"> attribute.

=item * target (B<required>)

Initial value for the L<target|/"target (required)"> attribute.

=back

=head2 ARGV

Accessor for the L<ARGV|/"ARGV (optional)"> attribute.

=head2 extra_argv

Accessor for the L<extra_argv|/"extra_argv (optional)"> attribute.

=head2 lib_paths

Reader for the L<lib_paths|/"lib_paths (required)"> attribute.

=head2 run

    ->run()

=over

=back

Runs the script.

=head2 settings_file

Reader for the L<settings_file|/"settings_file (optional)"> attribute.

=head2 target

Reader for the L<target|/"target (required)"> attribute.

=head2 target_is_dir

Delegation to the C<is_dir> method in the L<target|/target (required)> attribute.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Script> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 ARGV (optional)

=over

=item * Type Constraint

ArrayRef

=item * Constructor Argument

ARGV

=item * Associated Methods

L<ARGV|/ARGV>

=back

=head2 extra_argv (optional)

=over

=item * Type Constraint

ArrayRef

=item * Constructor Argument

extra_argv

=item * Associated Methods

L<extra_argv|/extra_argv>

=back

=head2 lib_paths (required)

=over

=item * Type Constraint

ArrayRef[Str]

=item * Default

Built during runtime.

=item * Constructor Argument

lib

=item * Associated Methods

L<lib_paths|/lib_paths>

=back

Paths to search for modules to load.

=head2 settings_file (optional)

=over

=item * Type Constraint

L<ExistingFile|Pod::MetaFusion::Types/ExistingFile>

=item * Constructor Argument

settings

=item * Associated Methods

L<settings_file|/settings_file>

=back

An optional settings file.

=head2 target (required)

=over

=item * Type Constraint

L<ExistingItem|Pod::MetaFusion::Types/ExistingItem>

=item * Constructor Argument

target

=item * Associated Methods

L<target|/target>, L<target_is_dir|/target_is_dir>

=back

The target that should be fused. Can be either a directory to scan or a single file.

=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * MooseX::Getopt

Version 0.24

=back

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=item * L<MooseX::Getopt>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut