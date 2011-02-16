### app.psgi
use Tatsumaki::Error;
use Tatsumaki::Application;
use Tatsumaki::HTTPClient;
use Tatsumaki::Server;

use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use Mojito::Page::Parse;
use Mojito::Page::CRUD;
use Mojito::Page::Render;
use Mojito::Page;
use Mojito::Template;

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
    my $pager = Mojito::Page->new( page => $Fixture::implicit_section );
    my $page_struct = $pager->page_structure;
    my $editer      = Mojito::Page::CRUD->new( db_name => 'bench' );
    my $id          = $editer->create($page_struct);

    #my $page             = $editer->read($id);
    my $rendered_content = $pager->render_page($page_struct);
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