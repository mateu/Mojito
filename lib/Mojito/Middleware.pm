use strictures 1;
package Mojito::Middleware;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw/config/;
use Mojito;

sub call {
    my ( $self, $env ) = @_;
    my $base_url = $env->{SCRIPT_NAME} || '/';
    $base_url =~ s/([^\/])$/$1\//;
    # TODO: Just use a hash instead of an object
    # and don't pass in stuff that we'll just be passing back
    # unless there's a justificaton (e.g. construct only once)
    $env->{"mojito"} = Mojito->new( 
        base_url => $base_url, 
        username => $env->{REMOTE_USER},
        config   => $self->config, 
    );
    $self->app->($env);
}

1;