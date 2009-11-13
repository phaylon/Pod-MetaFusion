use MooseX::Declare;

class Pod::MetaFusion::Report {

    use DateTime;
    use MooseX::Types::DateTime DateTime => { -as => 'DT' };
    use Pod::MetaFusion::Types  qw( ExistingItem );

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

    method done { $self->finished_at(DateTime->now) }

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
        );
    }
}
