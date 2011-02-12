### app.psgi
use Tatsumaki::Error;
use Tatsumaki::Application;
use Tatsumaki::HTTPClient;
use Tatsumaki::Server;

package MainHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    $self->write("Hello World");
}

package HolaNameHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self, $name) = @_;
    $self->write("Hola $name");
}

package main;

my $app = Tatsumaki::Application->new([
#    '/stream' => 'StreamWriter',
#    '/feed/(\w+)' => 'FeedHandler',
    '/' => 'MainHandler',
    '/hola/(\w+)' => 'HolaNameHandler',
]);

return $app;