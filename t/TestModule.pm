use MooseX::Declare;

class TestBase {
    use MooseX::Types::Path::Class qw( File );
    use Moose::Util::TypeConstraints;

    class_type;
    has file  => (is => 'ro', isa => File, documentation => 'A file we use.');
    has class => (is => 'rw', isa => __PACKAGE__);
}

class TestModule extends TestBase with TestRole {
    use MooseX::Types::Moose qw( Int HashRef );
    use MooseX::Types::Structured qw( Dict );

    has foo  => (is => 'rw', isa => Int, documentation => 'this is a foo');
    has dict => (is => 'ro', isa => Dict[foo => HashRef], required => 1);

    method fnord (Int $x, Dict[foo => Int] $y) { $x }
    method no_type ($foo) { $foo }
    method classmethod (ClassName $x: $y) { $y }
    method named (Int :$x) { $x }
    method rest ($n, @ns) { $n }
    method mixed (Int $n, Str :$y) { 23 }
}

=begin fusion

@see_also MooseX::Declare
@note_version Moose
@license OtherModule
@CLASS TestModule

Abstract

@ATTR foo

Attribute description.

@method fnord
%param $x the integer we return
%param $y the integer we discard

Additional method info.

@method named
%param :$x a named int

@method new

Additionally you can pass in C<fnord> to reboot the internet.

@DESCRIPTION

This is the description.

@SYNOPSIS

    $foo->bar(23);

=end fusion



=head1 NAME

TestModule - Abstract

=head1 SYNOPSIS

    $foo->bar(23);

=head1 INHERITANCE

=over 2

=item *

TestModule

=over 2

=item *

L<TestBase>

=over 2

=item *

L<Moose::Object>


=back

=back

=back

=head1 APPLIED ROLES

=over

=item * L<TestRole>



=back


=head1 DESCRIPTION

This is the description.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters;

=over

=item * class (optional)

Initial value for the L<class|TestBase/"class (optional)"> attribute.

=item * dict (B<required>)

Initial value for the L<dict|/"dict (required)"> attribute.

=item * file (optional)

Initial value for the L<file|TestBase/"file (optional)"> attribute.

=item * foo (optional)

Initial value for the L<foo|/"foo (optional)"> attribute.

=back


Additionally you can pass in C<fnord> to reboot the internet.

=head2 classmethod

    ->classmethod(ClassName $x: $y)

=over

=item * Positional Parameters:

=over

=item * $y



=back


=back


=head2 dict

Reader for the L<dict|/"dict (required)"> attribute.

=head2 fnord

    ->fnord(Int $x, Dict["foo",Int] $y)

=over

=item * Positional Parameters:

=over

=item * Int $x

the integer we return

=item * Dict["foo",Int] $y

the integer we discard

=back


=back


Additional method info.

=head2 foo

Accessor for the L<foo|/"foo (optional)"> attribute.

=head2 mixed

    ->mixed(Int $n, Str :$y)

=over

=item * Positional Parameters:

=over

=item * Int $n



=back


=item * Named Parameters:

=over

=item * Str :$y



=back


=back


=head2 named

    ->named(Int :$x)

=over

=item * Named Parameters:

=over

=item * Int :$x

a named int

=back


=back




=head2 no_type

    ->no_type($foo)

=over

=item * Positional Parameters:

=over

=item * $foo



=back


=back


=head2 rest

    ->rest($n, @ns)

=over

=item * Positional Parameters:

=over

=item * $n



=item * @ns



=back


=back


=head2 meta

Returns the meta object for C<TestModule> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 dict (required)

=over

=item * Type Constraint

L<MooseX::Types::Structured::Dict|MooseX::Types::Structured/Dict>[foo,HashRef]

=back

=head2 foo (optional)

this is a foo

=over

=item * Type Constraint

Int

=back

Attribute description.


=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * Moose

Version 0.92

=back

=head1 SEE ALSO

=over

=item * MooseX::Declare



=back


=head1 LICENSE AND COPYRIGHT

See L<OtherModule> for information about license and copyright




=cut