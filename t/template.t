use Test::More;
use Mojito::Template;
use 5.010;

my $temple = Mojito::Template->new;
say "template: ", $temple->template;

ok(1);


done_testing();