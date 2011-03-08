use strictures 1;
use Plack::Test;
use Plack::Util;
use Test::More;
use HTTP::Request;
use FindBin qw($Bin);

my @app_files = (
    "$Bin/../app/dancer.pl", "$Bin/../app/mojito.pl",
    "$Bin/../app/mojo.pl",   "$Bin/../app/tatsumaki.psgi"
);

foreach my $app_file (@app_files) {
    my $app = Plack::Util::load_psgi $app_file;
    test_psgi app => $app, client => sub {
        my $client_cb = shift;

        my $request = HTTP::Request->new( GET => 'http://localhost/public/feed/ironman' );
        my $response = $client_cb->($request);

        is   $response->code,    200;
        like $response->content, qr/Articles/;
    };

}

done_testing;
