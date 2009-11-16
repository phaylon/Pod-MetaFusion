use inc::Module::Install;

name            'Pod-MetaFusion';
all_from        'lib/Pod/MetaFusion.pm';
install_script  'script/pod-metafusion';

requires 'CLASS';
requires 'DateTime';
requires 'List::AllUtils';
requires 'Moose';
requires 'MooseX::Declare';
requires 'MooseX::Types::DateTime';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types';
requires 'MooseX::Types::Structured';
requires 'PPI';
requires 'Path::Class';
requires 'Text::Balanced';
requires 'namespace::autoclean';
requires 'aliased';
requires 'Pod::Elemental';

WriteAll;
