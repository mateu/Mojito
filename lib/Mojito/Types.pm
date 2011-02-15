use strictures 1;
package Mojito::Types;
use Sub::Quote qw(quote_sub);
use Scalar::Util;
use List::Util;

=head1 Methods

=head2 Num

A number type

=cut

sub Num () {  ## no critic
    quote_sub q{
        die "$_[0] is not a Number!" unless Scalar::Util::looks_like_number($_[0]);
    };
}

=head2 Int

An integer type

=cut

sub Int () {  ## no critic
    quote_sub q{
        die "$_[0] is not a Integer!" unless ((Scalar::Util::looks_like_number($_[0])) && ($_[0] == int $_[0]));
    };
}

=head2 ArrayRef

An ArrayRef type

=cut

sub ArrayRef () {  ## no critic
    quote_sub q{ die "$_[0] is not an ArrayRef!" if ref($_[0]) ne 'ARRAY' };
}

=head2 HashRef

A HashRef type

=cut

sub HashRef () {  ## no critic
    quote_sub q{ die "$_[0] is not an HashRef!" if ref($_[0]) ne 'HASH' };
}

=head2 RegexpRef

A regular expression reference type

=cut

sub RegexpRef () {  ## no critic
    quote_sub q{ die "$_[0] is not an RegexRef!" if ref($_[0]) ne 'Regexp' };
}

=head2 AHRef

An ArrayRef[HashRef] type

=cut

sub AHRef {  ## no critic
    quote_sub q{ 
        die "$_[0] is not an ArrayRef[HashRef]!" 
          if ((ref($_[0]) ne 'ARRAY') || ( List::Util::first { ref($_) ne 'HASH' } @{$_[0]} )) 
    };
}

=head2 NoRef

A non-reference type

=cut

sub NoRef () {  ## no critic
    quote_sub q{ 
        die "$_[0] is a referernce" if ref($_[0])
    };
}

=head2 Bool

A boolean 1|0 type

=cut

sub Bool () {  ## no critic
    quote_sub q{ 
        die "$_[0] not a Boolean" if ($_[0] != 0 && $_[0] != 1);
    };
}

1;