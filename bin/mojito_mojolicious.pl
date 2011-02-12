#!/usr/bin/env perl
use Mojolicious::Lite;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use PageParse;
use PageCRUD;
use PageRender;
use Template;
#use Data::Dumper::Concise;

my $tmpl = Template->new;

get '/bench' => sub {
    my $self        = shift;
    my $parser      = PageParse->new( page => $Fixture::implicit_section );
    my $page_struct = $parser->page_structure;
    my $editer      = PageCRUD->new;
    my $id  =  '4d56c014fbb0bcf24e000000'; 
    my $page   = $editer->read($id);
    my $render = PageRender->new;
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
    
    my $parser           = PageParse->new( page => $self->param('content') );
    my $page_struct      = $parser->page_structure;
    my $render           = PageRender->new;
    my $rendered_content = $render->render_body($page_struct);
    my $response_href    = { rendered_content => $rendered_content };

    $self->render( json => $response_href );
};



app->start;
