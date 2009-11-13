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
coerce ExistingDir,  from ExistingDirPath,  via { to_dir $_ };

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(@$_) for
    [ExistingFile,  '=s'],
    [ExistingItem,  '=s'],
    [ExistingDir,   '=s'];

1;
