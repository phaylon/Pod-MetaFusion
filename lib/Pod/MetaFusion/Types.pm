package Pod::MetaFusion::Types;
use MooseX::Types
    -declare => [qw(
        ExistingFile
        ExistingDir
        ExistingItem
        ExistingPath
        ExistingFilePath
        ExistingDirPath
    )];

use MooseX::Types::Moose        qw( :all );
use MooseX::Types::Path::Class  qw( :all );
use namespace::autoclean;

subtype ExistingFile,       as File,            where { -f },   message { "File does not exist: $_" };
subtype ExistingDir,        as Dir,             where { -d },   message { "Directory does not exist: $_" };
subtype ExistingItem,       as ExistingFile | ExistingDir,      message { "File or directory does not exist: $_" };
subtype ExistingPath,       as Str,             where { -e },   message { "File or directory does not exist: $_" };
subtype ExistingFilePath,   as ExistingPath,    where { -f },   message { "File does not exist: $_" };
subtype ExistingDirPath,    as ExistingPath,    where { -d },   message { "Directory does not exist: $_" };

#coerce ExistingItem, from ExistingPath,     via { (-d $_) ? to_Dir($_) : to_File($_) };
coerce ExistingFile, from ExistingFilePath, via { to_File $_ };
coerce ExistingDir,  from ExistingDirPath,  via { to_Dir $_ };

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(@$_) for
    [ExistingFile,  '=s'],
    [ExistingItem,  '=s'],
    [ExistingDir,   '=s'];

1;

__END__

=begin fusion

@see_also Pod::MetaFusion
@see_also MooseX::Types
@license  Pod::MetaFusion

@typelib Pod::MetaFusion::Types
Types for L<Pod::MetaFusion>

@type ExistingFile
Path to an existing file.

@type ExistingDir
Path to an existing directory.

@type ExistingItem
Path to an existing file or directory.

@type ExistingPath
String path that exists physically on the file system.

@type ExistingFilePath
String path that exists as file on the file system.

@type ExistingDirPath
String path that exists as directory on the file system.

=end fusion






=head1 NAME

Pod::MetaFusion::Types - Types for L<Pod::MetaFusion>

=head1 TYPES

=head2 ExistingFile

Subtype of L<File|MooseX::Types::Path::Class/File>

Available coercions:

=over

=item * L<ExistingFilePath|Pod::MetaFusion::Types/ExistingFilePath>

=back

Path to an existing file.

=head2 ExistingFilePath

Subtype of L<ExistingPath|/ExistingPath>

String path that exists as file on the file system.

=head2 ExistingDirPath

Subtype of L<ExistingPath|/ExistingPath>

String path that exists as directory on the file system.

=head2 ExistingDir

Subtype of L<Dir|MooseX::Types::Path::Class/Dir>

Available coercions:

=over

=item * L<ExistingDirPath|Pod::MetaFusion::Types/ExistingDirPath>

=back

Path to an existing directory.

=head2 ExistingPath

Subtype of Str

String path that exists physically on the file system.

=head2 ExistingItem

Subtype of L<ExistingDir|/ExistingDir>|L<ExistingFile|/ExistingFile>

Path to an existing file or directory.

=head1 SEE ALSO

=over

=item * L<Pod::MetaFusion>

=item * L<MooseX::Types>

=back

=head1 LICENSE AND COPYRIGHT

See L<Pod::MetaFusion> for information about license and copyright.

=cut