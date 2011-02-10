use Test::More;
use Template;
use 5.010;

my $temple = Template->new;
say "template: ", $temple->template;

ok(1);


done_testing();