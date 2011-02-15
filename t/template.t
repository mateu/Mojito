use Test::More;
use Mojito::Template;
use 5.010;

my $temple = Mojito::Template->new;
isa_ok($temple, 'Mojito::Template');


done_testing();