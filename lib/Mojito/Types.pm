package Mojito::Types;
use Sub::Quote qw(quote_sub);
use Scalar::Util;
use List::Util;

sub Num () {
    quote_sub q{
        die "$_[0] is not a Number!" unless Scalar::Util::looks_like_number($_[0]);
    };
}

sub Int () {
    quote_sub q{
        die "$_[0] is not a Integer!" unless ((Scalar::Util::looks_like_number($_[0])) && ($_[0] == int $_[0]));
    };
}

sub ArrayRef () {
    quote_sub q{ die "$_[0] is not an ArrayRef!" if ref($_[0]) ne 'ARRAY' };
}

sub HashRef () {
    quote_sub q{ die "$_[0] is not an HashRef!" if ref($_[0]) ne 'HASH' };
}

sub RegexpRef () {
    quote_sub q{ die "$_[0] is not an RegexRef!" if ref($_[0]) ne 'Regexp' };
}

sub AHRef {
    quote_sub q{ 
        die "$_[0] is not an ArrayRef[HashRef]!" 
          if ((ref($_[0]) ne 'ARRAY') || ( List::Util::first { ref($_) ne 'HASH' } @{$_[0]} )) 
    };
}

sub NoRef () {
    quote_sub q{ 
        die "$_[0] is a referernce" if ref($_[0])
    };
}

sub Bool () {
    quote_sub q{ 
        die "$_[0] not a Boolean" if ($_[0] != 0 && $_[0] != 1);
    };
}

1;