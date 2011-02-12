### app.psgi
use Tatsumaki::Error;
use Tatsumaki::Application;
use Tatsumaki::HTTPClient;
use Tatsumaki::Server;

use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use PageParse;
use PageCRUD;
use PageRender;
use Template;

package MainHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my $self = shift;
    $self->write("Hello World");
}

package HolaNameHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $name ) = @_;
    $self->write("Hola $name");
}

package BenchHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $name ) = @_;
    my $parser           = PageParse->new( page => $Fixture::implicit_section );
    my $page_struct      = $parser->page_structure;
    my $editer           = PageCRUD->new;
    my $id               = '4d56c014fbb0bcf24e000000';
    my $page             = $editer->read($id);
    my $render           = PageRender->new;
    my $rendered_content = $render->render_page($page_struct);
    $self->write($rendered_content);
}

package main;

my $app = Tatsumaki::Application->new(
    [
        '/'           => 'MainHandler',
        '/hola/(\w+)' => 'HolaNameHandler',
        '/bench'      => 'BenchHandler',
    ]
);

return $app;
