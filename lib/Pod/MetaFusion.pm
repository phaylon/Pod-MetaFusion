use MooseX::Declare;

class Pod::MetaFusion with MooseX::SimpleConfig {

    use MooseX::Types::Moose    qw( HashRef );
    use Pod::MetaFusion::Types  qw( ExistingItem ExistingFile ExistingDir );

    use aliased 'Pod::MetaFusion::Report';
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

    method fuse (ExistingItem $target, Object :$report?) {

        return $self->_fuse_dir($target) if $target->is_dir;
        require PPI::Document::File;

        my $transform = Module->new(
            $self->_module_config_list,
          ( $report ? (fusion_report => $report) : () ),
        );
        my $doc = PPI::Document::File->new($target->stringify);
        $transform->apply($doc);
        $doc->save;

        return $transform->fusion_report;
    }

    method _fuse_dir (ExistingDir $target) {

        my $report = Report->new;

        $target->recurse(callback => sub {
            my $object = shift;

            if (not($object->is_dir) and $object =~ /\.pm\Z/) {
                $self->fuse($object, report => $report);
            }
        });

        return $report;
    }
}

__END__

=begin fusion

@note_version Moose
@note_version MooseX::SimpleConfig
@class Pod::MetaFusion

Fuse meta information into POD

@method fuse
%param $target  The file or directory that should be fused.
%param :$report Internal parameter.

If C<$target> is a file, it will be fused. If it is a directory, all C<.pm> files that can be found
will be fused.

@license

Copyright (c) 2009, Robert 'phaylon' Sedlacek.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=end fusion



=head1 NAME

Pod::MetaFusion - 
Fuse meta information into POD

=head1 VERSION

0.01

=head1 INHERITANCE

=over 2

=item *

Pod::MetaFusion

=over 2

=item *

L<Moose::Object>

=back

=back

=head1 APPLIED ROLES

=over

=item * L<MooseX::ConfigFromFile>

=item * L<MooseX::SimpleConfig>

=back

=head1 METHODS

=head2 new

Object constructor accepting the following parameters;

=over

=item * configfile (optional)

Initial value for the L<configfile|/"configfile (optional)"> attribute.

=item * modules (optional)

Initial value for the L<module_config|/"module_config (required)"> attribute.

=back

=head2 configfile

Reader for the L<configfile|/"configfile (optional)"> attribute.

=head2 fuse

    ->fuse(ExistingItem $target, Object :$report)

=over

=item * Positional Parameters:

=over

=item * L<ExistingItem|Pod::MetaFusion::Types/ExistingItem> C<$target>

 The file or directory that should be fused.

=back

=item * Named Parameters:

=over

=item * Object C<:$report>

Internal parameter.

=back

=back

If C<$target> is a file, it will be fused. If it is a directory, all C<.pm> files that can be found
will be fused.

=head2 has_configfile

Predicate for the L<configfile|/"configfile (optional)"> attribute.

=head2 module_config

Reader for the L<module_config|/"module_config (required)"> attribute.

=head2 meta

Returns the meta object for C<Pod::MetaFusion> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 configfile (optional)

=over

=item * Type Constraint

L<File|MooseX::Types::Path::Class/File>

=item * Constructor Argument

configfile

=item * Associated Methods

L<configfile|/configfile>, L<has_configfile|/has_configfile>

=back

=head2 module_config (required)

=over

=item * Type Constraint

HashRef

=item * Default

Built during runtime.

=item * Constructor Argument

modules

=item * Associated Methods

L<module_config|/module_config>

=back

=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * MooseX::SimpleConfig

Version 0.04

=item * Moose

Version 0.92

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Robert 'phaylon' Sedlacek.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut