use strictures 1;
package Mojito::Middleware;
use parent qw(Plack::Middleware);
use Mojito;

sub call {
    my ( $self, $env ) = @_;
    my $base_url = $env->{SCRIPT_NAME} || '/';
    $base_url =~ s/([^\/])$/$1\//;
    $env->{"mojito"} = Mojito->new( base_url => $base_url );
    $self->app->($env);
}

1