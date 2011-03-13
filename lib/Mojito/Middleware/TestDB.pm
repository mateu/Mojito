use strictures 1;
package Mojito::Middleware::TestDB;
use parent qw(Plack::Middleware);

# This middleware needs to be wrapped in after Mojito::Middleware
# which provides the $env->{mojito} object for which we adjust
# the connecting DB to a test one.

sub call {
    my ( $self, $env ) = @_;
    # This should be available since we wrap Mojito::Middleware around it
    # See the builder block.
    if ($env->{mojito}) {
        $env->{mojito}->editer->db_name('mojito_test');
        $env->{mojito}->linker->doc->db_name('mojito_test');
        #$env->{mojito}->editer->collection->remove();
    };
    $self->app->($env);
}

1