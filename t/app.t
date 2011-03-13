use strictures 1;
use 5.010;
use Plack::Test;
use Plack::Util;
use Test::More;
use HTTP::Request;
use HTTP::Request::Common;
use JSON;
use FindBin qw($Bin);
use Data::Dumper::Concise;

# Monkey patch Auth::Digest during testing to let me in the door.
BEGIN {
    if (!$ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }

    use Plack::Middleware::Auth::Digest;
    no warnings 'redefine';
    *Plack::Middleware::Auth::Digest::call = sub {
        my ($self, $env) = @_;
        $env->{REMOTE_USER} = 'hunter';
        return $self->app->($env);
    };

}
my @app_files = (
    "$Bin/../app/dancer.pl", "$Bin/../app/mojito.pl",
    "$Bin/../app/mojo.pl",   "$Bin/../app/tatsumaki.psgi"
);

@app_files = ( "$Bin/../app/tatsumaki.psgi" );

foreach my $app_file (@app_files) {
    my $app = Plack::Util::load_psgi $app_file;
    test_psgi app => $app, client => sub {
        my $client_cb = shift;

        my $request = HTTP::Request->new( GET => '/public/feed/ironman' );
        my $response = $client_cb->($request);
        is   $response->code,    200;
        like $response->content, qr/(Articles|empty)/;

        $request = HTTP::Request->new( GET => '/');
        $response = $client_cb->($request);
        is   $response->code,    200;
        like $response->content, qr/Recent Articles/;

        $request = HTTP::Request->new( GET => '/page');
        $response = $client_cb->($request);
        is   $response->code,    200;
        like $response->content, qr/id="edit_area"/;

        $request = POST '/page', [content => "h1. Perl Rocks"];
        $response = $client_cb->($request);
        like $response->code, qr/^(?:301|302)$/;

        $request = HTTP::Request->new( GET => '/recent');
        $response = $client_cb->($request);
        is   $response->code,    200;
        like $response->content, qr/Perl Rocks/;
       
        # Let's get page id from the recent page
        # so we can request a specific page then delete it. 
        my $content = $response->content;
        my ($id) = $content =~ m!<a href="/page/(\w+)">Perl Rocks</a>!;
        $request = HTTP::Request->new( GET => "/page/${id}");
        $response = $client_cb->($request);
        is   $response->code,    200;
        like $response->content, qr/Perl Rocks/;
        $request = HTTP::Request->new( GET => "/page/${id}/delete");
        $response = $client_cb->($request);
        like $response->code, qr/^(?:301|302)$/;

        $request = HTTP::Request->new( GET => '/recent');
        $response = $client_cb->($request);
        is   $response->code,    200;
        unlike $response->content, qr/${id}/;
        
        $request = POST '/preview', [content => '*Bom dia*'];
        $response = $client_cb->($request);
        is   $response->code,    200;
        my $hashref = decode_json($response->content);
        is $hashref->{rendered_content}, '<p><strong>Bom dia</strong></p>';
    };
}


done_testing;
