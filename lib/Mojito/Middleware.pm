use strictures 1;
package Mojito::Middleware;
use parent qw(Plack::Middleware);
use Mojito;
use Mojito::Page;

sub call {
    my ( $self, $env ) = @_;

    my $base_url = $env->{SCRIPT_NAME} || '/';
    $base_url =~ s/([^\/])$/$1\//;
    my $mojito = Mojito->new( base_url => $base_url );
    my $pager = Mojito::Page->new(
        {
            page     => '<sx>Mojito page</sx>',
            base_url => $base_url,
        }
    );
    $env->{"mojito.base_url"} = $base_url;
    $env->{"mojito.object"}   = $mojito;
    $env->{"mojito.pager"}    = $pager;
    $self->app->($env);
}

1