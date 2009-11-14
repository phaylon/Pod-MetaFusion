use MooseX::Declare;

class Pod::MetaFusion::Report {

    use DateTime;
    use MooseX::Types::DateTime DateTime => { -as => 'DT' };
    use Pod::MetaFusion::Types  qw( ExistingItem ExistingFile );
    use MooseX::Types::Moose    qw( ArrayRef );

    has started_at => (
        is          => 'ro',
        isa         => DT,
        required    => 1,
        default     => sub { DateTime->now },
    );

    has finished_at => (
        is          => 'rw',
        isa         => DT,
    );

    for my $type (qw( skipped rebuilt )) {

        has $type => (
            traits      => [qw( Array )],
            isa         => ArrayRef[ExistingFile],
            required    => 1,
            default     => sub { [] },
            init_arg    => undef,
            handles     => {
                "add_$type"     => 'push',
                "all_$type"     => 'elements',
                "${type}_count" => 'count',
            },
        );
    }

    method done () { $self->finished_at(DateTime->now) }

    method display (@args) { print $self->as_string(@args) }

    method as_string (ExistingItem $target) {
        require Pod::MetaFusion;

        return join '', map(
            "$_\n",
            sprintf(
                '%s %s report for %s (%s):', 
                'Pod::MetaFusion', 
                Pod::MetaFusion->VERSION, 
                $target,
              ( $target->is_dir ? 'directory' : 'file' ),
            ),
            sprintf('started at  %s %s', $self->started_at->dmy('.'),  $self->started_at->hms(':')),
            sprintf('finished at %s %s', $self->finished_at->dmy('.'), $self->finished_at->hms(':')),
            '',
          ( $self->skipped_count ? (
            'skipped: ',
            (map { "  $_" } $self->all_skipped),
            '',
          ) : () ),
          ( $self->rebuilt_count ? (
            'rebuilt: ',
            (map { "  $_" } $self->all_rebuilt),
            '',
          ) : () ),
        );
    }
}

__END__

=begin fusion

@note_version   Moose
@see_also       Pod::MetaFusion
@license        Pod::MetaFusion

@class Pod::MetaFusion::Report
Collect information during fuse

@method as_string
%param $target This is the filesystem path that will be displayed in the report.
Format the collected data as a report string.

@method display
%param @args Will be passed on to the L</as_string> method.
Format the collected information and print it to standard output.

@method done
Marks this report as done.

@attr finished_at
Set by L</done>. Contains the point in time when the collecting of information
was finished.

@attr rebuilt
List of rebuilt files.

@attr skipped
List of files that have been skipped, probably because they don't have fusion
sections.

@attr started_at
Set at build to the current point in time.

=end fusion



=head1 NAME

Pod::MetaFusion::Report - Collect information during fuse

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion::Report

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters;

=over

=item * finished_at (optional)

Initial value for the L<finished_at|/"finished_at (optional)"> attribute.

=item * started_at (optional)

Initial value for the L<started_at|/"started_at (required)"> attribute.

=back

=head2 add_rebuilt

Delegation to a generated method in the L<rebuilt|/rebuilt (required)> attribute.

=head2 add_skipped

Delegation to a generated method in the L<skipped|/skipped (required)> attribute.

=head2 all_rebuilt

Delegation to a generated method in the L<rebuilt|/rebuilt (required)> attribute.

=head2 all_skipped

Delegation to a generated method in the L<skipped|/skipped (required)> attribute.

=head2 as_string

    ->as_string(ExistingItem $target)

=over

=item * Positional Parameters:

=over

=item * L<ExistingItem|Pod::MetaFusion::Types/ExistingItem> $target

This is the filesystem path that will be displayed in the report.

=back

=back

Format the collected data as a report string.

=head2 display

    ->display(@args)

=over

=item * Positional Parameters:

=over

=item * @args

Will be passed on to the L</as_string> method.

=back

=back

Format the collected information and print it to standard output.

=head2 done

    ->done()

=over

=back

Marks this report as done.

=head2 finished_at

Accessor for the L<finished_at|/"finished_at (optional)"> attribute.

=head2 rebuilt_count

Delegation to a generated method in the L<rebuilt|/rebuilt (required)> attribute.

=head2 skipped_count

Delegation to a generated method in the L<skipped|/skipped (required)> attribute.

=head2 started_at

Reader for the L<started_at|/"started_at (required)"> attribute.

=head2 meta

Returns the meta object for C<Pod::MetaFusion::Report> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 finished_at (optional)

=over

=item * Type Constraint

L<DateTime|MooseX::Types::DateTime/DateTime>

=item * Constructor Argument

finished_at

=item * Associated Methods

L<finished_at|/finished_at>

=back

Set by L</done>. Contains the point in time when the collecting of information
was finished.

=head2 rebuilt (required)

=over

=item * Type Constraint

ArrayRef[L<ExistingFile|Pod::MetaFusion::Types/ExistingFile>]

=item * Default

Built during runtime.

=item * Constructor Argument

This attribute can not be set in the constructor.

=item * Associated Methods

L<all_rebuilt|/all_rebuilt>, L<add_rebuilt|/add_rebuilt>, L<rebuilt_count|/rebuilt_count>

=back

List of rebuilt files.

=head2 skipped (required)

=over

=item * Type Constraint

ArrayRef[L<ExistingFile|Pod::MetaFusion::Types/ExistingFile>]

=item * Default

Built during runtime.

=item * Constructor Argument

This attribute can not be set in the constructor.

=item * Associated Methods

L<skipped_count|/skipped_count>, L<add_skipped|/add_skipped>, L<all_skipped|/all_skipped>

=back

List of files that have been skipped, probably because they don't have fusion
sections.

=head2 started_at (required)

=over

=item * Type Constraint

L<DateTime|MooseX::Types::DateTime/DateTime>

=item * Default

Built during runtime.

=item * Constructor Argument

started_at

=item * Associated Methods

L<started_at|/started_at>

=back

Set at build to the current point in time.

=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * Moose

Version 0.92

=back

=head1 SEE ALSO

=over

=item * Pod::MetaFusion

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut