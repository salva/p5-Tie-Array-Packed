package Tie::Array::Packed;

use 5.008;

our $VERSION = '0.02';

use strict;
use warnings;

require XSLoader;
XSLoader::load('Tie::Array::Packed', $VERSION);

my @short = qw(c C F f d i I i! I! s! S! l! L! n N v V);

my %map = ( Char => 'c',
            UnsignedChar => 'C',
            NV => 'F',
            Number => 'F',
            FloatNative => 'f',
            DoubleNative => 'd',
            Integer => 'i',
            UnsignedInteger => 'I',
            IntegerNative => 'i!',
            UnsignedIntegerNative => 'I!',
            ShortNative => 's!',
            UnsignedShortNative => 'S!',
            LongNative => 'l!',
            UnsignedLongNative => 'L!',
            UnsignedShortNet => 'n',
            UnsignedShortBE => 'n',
            UnsignedLongNet => 'N',
            UnsignedLongBE => 'N',
            UnsignedShortVax => 'v',
            UnsignedShortLE => 'v',
            UnsignedLongVax => 'V',
            UnsignedLongLE => 'V' );


@map{@short} = @short;

for my $name (keys %map) {
    my $type = $map{$name};

    no strict 'refs';
    @{"Tie::Array::Packed::${name}::ISA"} = __PACKAGE__;
    *{"Tie::Array::Packed::${name}::TIEARRAY"} =
        sub {
            my $class = shift;
            my $self;
            $self = TIEARRAY($class, $type, @_ ? shift : '');
            $self->SPLICE(0, scalar(@_), @_) if @_;
            $self;
        };
}

sub make {
    my $class = shift;
    tie my(@self), $class, '', @_;
    return \@self
}

sub make_with_packed {
    my $class = shift;
    tie my(@self), $class, @_;
    return \@self
}



sub string {
    my $self = shift;
    $$self;
}

1;
__END__

=head1 NAME

Tie::Array::Packed - store arrays in memory efficiently as packed strings

=head1 SYNOPSIS

  use Tie::Array::Packed;

  my (@foo, @bar);
  tie @foo, Tie::Array::Packed::Integer;
  tie @bar, Tie::Array::Packed::DoubleNative;

  $foo[12] = 13;
  $bar[1] = 4.56;

  pop @foo;
  @some = splice @bar, 1, 3, @foo;

=head1 DESCRIPTION

This module provides an implementation for tied arrays that uses as
storage a Perl scalar where all the values are packed as if the
C<pack> builtin had been used.

All the values on a Tie::Array::Packed array are of the same value
(integers, shorts, doubles, etc.)

The module is written in XS for speed. Tie::Array::Packed arrays are
aproximately 15 times slower than native ones (for comparison to a
pure Perl implementation, arrays tied with L<Tie::Array::PackedC> are
around 60 times slower than native arrays).

On the other hand, packed arrays use between 4 and 12 times less
memory that the native ones.

=head1 USAGE

Tie::Array::Packed defines a set of classes that can be used to tie
arrays. The classes have names of the form:

  Tie::Array::Packed::<Type>

and are as follows:

                                           pack      C
            class name                    pattern   type
  --------------------------------------------------------------------
  Tie::Array::Packed::Char                   c     char
  Tie::Array::Packed::UnsignedChar           C     unsigned char
  Tie::Array::Packed::NV                     F     NV
  Tie::Array::Packed::Number                 F     NV
  Tie::Array::Packed::FloatNative            f     float
  Tie::Array::Packed::DoubleNative           d     double
  Tie::Array::Packed::Integer                i     IV
  Tie::Array::Packed::UnsignedInteger        I     UV
  Tie::Array::Packed::IntegerNative          i!    int
  Tie::Array::Packed::UnsignedIntegerNative  I!    unsigned int
  Tie::Array::Packed::ShortNative            s!    short
  Tie::Array::Packed::UnsignedShortNative    S!    unsigned short
  Tie::Array::Packed::LongNative             l!    long
  Tie::Array::Packed::UnsignedLongNative     L!    unsigned long
  Tie::Array::Packed::UnsignedShortNet       n     -
  Tie::Array::Packed::UnsignedShortBE        n     -
  Tie::Array::Packed::UnsignedLongNet        N     -
  Tie::Array::Packed::UnsignedLongBE         N     -
  Tie::Array::Packed::UnsignedShortVax       v     -
  Tie::Array::Packed::UnsignedShortLE        v     -
  Tie::Array::Packed::UnsignedLongVax        V     -
  Tie::Array::Packed::UnsignedLongLE         V     -

if your C compiler has support for 64bit long long integers, then this two
classes will be also available:

                                           pack      C
            class name                    pattern   type
  --------------------------------------------------------------------
  Tie::Array::Packed::LongLong                q     long long
  Tie::Array::Packed::UnsignedLongLong        Q     unsigned long long


The tie interface for those clases is:

  tie @foo, Tie::Array::Packed::Integer;
  tie @foo, Tie::Array::Packed::Integer, $init_string, @values

(Tie::Array::Packed::Integer is used for example, the same applies to
the rest of the classes).

When a scalar value C<$init_string> is passed as an argument
it is used as the initial value for the storage scalar.

Additional arguments are used to initialize the array, for instance:

  tie @foo, Tie::Array::Packed::Char, '', 1, 2, 3;
  print "@foo"; # prints "1 2 3"

  tie @bar, Tie::Array::Packed::Char, 'hello';
  print "@bar"; # prints "104 101 108 108 111"

  tie @doz, Tie::Array::Packed::Char, 'hello', 1, 2, 3;
  print "@doz"; # prints "1 2 3 108 111";

The underlaying storage scalar can be accessed unreferencing the
object returned by tie:

  my $obj = tied(@foo);
  print "storage: ", $$obj;

=head2 METHODS

Those are the methods provided by the classes defined on the module:

=over 4

=item Tie::Array::Packed::Integer->make()

=item Tie::Array::Packed::Integer->make(@init_values)

This class method returns a reference to and array tied to the
class.

Note that the returned array is not blessed into any package.



=item Tie::Array::Packed::Integer->make_with_packed($init_string)

=item Tie::Array::Packed::Integer->make_with_packed($init_string, @init_values)

similar to the method before but get an additional argument to
initialize the storage scalar.

=item tied(@foo)->packer

returns the pack template in use for the elements of the tied array
C<@foo>.

=head1 BUGS

This is an early release, critical bugs may appear.

Only tested on Linux, though it should work on any OS with a decent C
compiler.

To report bugs on this module email me to the address that appears
below or use the CPAN RT system.

=head1 SEE ALSO

Documentation for Perl builtins L<pack> and L<vec>.

L<Tie::Array::PackedC> offers very similar functionality, but it is
implemented in pure Perl and so it is slower.

L<Array::Packed> is implemented in C but only supports integer values.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Salvador FandiE<ntilde>o (sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
