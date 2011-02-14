#!/usr/bin/env perl
use Mojolicious::Lite;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use Mojito::Page::Parse;
use Mojito::Page::CRUD;
use Mojito::Page::Render;
use Template;
#use Data::Dumper::Concise;

my $tmpl = Template->new;

get '/bench' => sub {
    my $self        = shift;
    my $parser      = Mojito::Page::Parse->new( page => $Fixture::implicit_section );
    my $page_struct = $parser->page_structure;
    my $editer      = Mojito::Page::CRUD->new;
    my $id  =  '4d56c014fbb0bcf24e000000'; 
    my $page   = $editer->read($id);
    my $render = Mojito::Page::Render->new;
    my $rendered_content = $render->render_page($page_struct);
    $self->render( text => $rendered_content );
};

get '/' => sub { shift->render( text => 'Hello World!' ) };

get '/hola/:name' => sub {
    my $self = shift;
    $self->render( text => "Hola " . $self->param('name') );
};

get '/page' => sub {
    my $self = shift;
    $self->render( text => $tmpl->template );
};

post '/page' => sub {
    my $self = shift;
    
    my $parser           = Mojito::Page::Parse->new( page => $self->param('content') );
    my $page_struct      = $parser->page_structure;
    my $render           = Mojito::Page::Render->new;
    my $rendered_content = $render->render_body($page_struct);
    my $response_href    = { rendered_content => $rendered_content };

    $self->render( json => $response_href );
};



app->start;
