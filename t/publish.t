use strictures 1;
use Test::More;
use WWW::Mechanize;
use Mojito::Page::Publish;
use 5.010;
use utf8;

BEGIN {
    if (!$ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
}

my $pub = Mojito::Page::Publish->new(target_page => 'hunter/mi-test', content => 'Visca el Barça');
ok($pub->publish);

done_testing();