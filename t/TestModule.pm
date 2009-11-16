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
    use Moose::Util::TypeConstraints;

    our $VERSION = 0.01;
    class_type;

    has foo  => (is => 'rw', isa => Int, documentation => 'this is a foo');
    has dict => (is => 'ro', isa => Dict[foo => HashRef], required => 1);
    has myclass => (is => 'rw', isa => __PACKAGE__);

    method fnord (Int $x, Dict[foo => Int] $y) { $x }
    method no_type ($foo) { $foo }
    method classmethod (ClassName $x: $y) { $y }
    method named (Int :$x) { $x }
    method rest ($n, @ns) { $n }
    method mixed (Int $n, Str :$y) { 23 }
    method with_a_very (Int :$looong!, ArrayRef[HashRef[ArrayRef[Int]]] :$signature?) { 23 }
}

__END__

=encoding utf-8

=begin fusion

@see_also MooseX::Declare
@note_version Moose
@license OtherModule
@CLASS TestModule

Abstract λ text

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

=head2 Foo

This is foo.

=head1 BAR

This is bar.

=head2 Baz

This is baz.

@SYNOPSIS

    $foo->bar(23);

=end fusion






=head1 NAME

TestModule - 
Abstract λ text

=head1 VERSION

0.01

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

=head2 Foo

This is foo.

=head1 BAR

This is bar.

=head2 Baz

This is baz.

=head1 METHODS

=head2 new

Object constructor accepting the following parameters:

=over

=item * class (optional)

Initial value for the inherited L<class|TestBase/"class (optional)"> attribute.

=item * dict (B<required>)

Initial value for the L<dict|/"dict (required)"> attribute.

=item * file (optional)

Initial value for the inherited L<file|TestBase/"file (optional)"> attribute.

=item * foo (optional)

Initial value for the L<foo|/"foo (optional)"> attribute.

=item * myclass (optional)

Initial value for the L<myclass|/"myclass (optional)"> attribute.

=back

Additionally you can pass in C<fnord> to reboot the internet.

=head2 classmethod

    ->classmethod(ClassName $x: $y)

=over

=item * Positional Parameters:

=over

=item * C<$y>

=back

=back

=head2 dict

Reader for the L<dict|/"dict (required)"> attribute.

=head2 fnord

    ->fnord(Int $x, Dict["foo",Int] $y)

=over

=item * Positional Parameters:

=over

=item * Int C<$x>

the integer we return

=item * L<Dict|MooseX::Types::Structured/Dict>[foo,Int] C<$y>

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

=item * Int C<$n>

=back

=item * Named Parameters:

=over

=item * Str C<:$y> (optional)

=back

=back

=head2 myclass

Accessor for the L<myclass|/"myclass (optional)"> attribute.

=head2 named

    ->named(Int :$x)

=over

=item * Named Parameters:

=over

=item * Int C<:$x> (optional)

a named int

=back

=back

=head2 no_type

    ->no_type($foo)

=over

=item * Positional Parameters:

=over

=item * C<$foo>

=back

=back

=head2 rest

    ->rest($n, @ns)

=over

=item * Positional Parameters:

=over

=item * C<$n>

=item * C<@ns>

=back

=back

=head2 with_a_very

    ->with_a_very(
        Int :$looong!,
        ArrayRef[
            HashRef[
                ArrayRef[
                    Int
                ]
            ]
        ] :$signature
    )

=over

=item * Named Parameters:

=over

=item * Int C<:$looong>

=item * ArrayRef[HashRef[ArrayRef[Int]]] C<:$signature> (optional)

=back

=back

=head2 meta

Returns the meta object for C<TestModule> as an instance of L<Class::MOP::Class::Immutable::Moose::Meta::Class>

=head1 ATTRIBUTES

=head2 dict (required)

=over

=item * Type Constraint

L<Dict|MooseX::Types::Structured/Dict>[foo,HashRef]

=item * Constructor Argument

dict

=item * Associated Methods

L<dict|/dict>

=back

=head2 foo (optional)

this is a foo

=over

=item * Type Constraint

Int

=item * Constructor Argument

foo

=item * Associated Methods

L<foo|/foo>

=back

Attribute description.

=head2 myclass (optional)

=over

=item * Type Constraint

L<TestModule>

=item * Constructor Argument

myclass

=item * Associated Methods

L<myclass|/myclass>

=back

=head1 ASSUMED VERSIONS

This document has been rendered against the following prerequisites:

=over

=item * Moose

Version 0.92

=back

=head1 SEE ALSO

=over

=item * L<MooseX::Declare>

=back

=head1 LICENSE AND COPYRIGHT

See L<OtherModule> for information about license and copyright.

=cut