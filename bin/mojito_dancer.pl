#!/usr/bin/env perl
use Dancer ':syntax';
use Dancer::Plugin::Ajax;
#use Simple;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../../../dev/Mojito/lib";
use lib __DIR__ . "/../../../dev/Mojito/t/data";
use Fixture;
use Mojito::Page::Parse;
use Mojito::Page::CRUD;
use Mojito::Page::Render;
use Template;
use JSON;

my $tmpl = Template->new;

#set 'logger' => 'console';
#set 'log' => 'debug';
#set 'show_errors' => 1;
#set 'access_log' => 1;
#set 'warnings' => 1;


our $VERSION = '0.1';

get '/bench' => sub {

    my $parser      = Mojito::Page::Parse->new( page => $Fixture::implicit_section );
    my $page_struct = $parser->page_structure;
    my $editer      = Mojito::Page::CRUD->new;
    my $id = '4d56c014fbb0bcf24e000000';
    my $page        = $editer->read($id);
    my $render      = Mojito::Page::Render->new;
    my $rendered_content = $render->render_page($page_struct);

    return $rendered_content;
};

get '/' => sub {
    template 'index';
};

get '/hola/:name' => sub {
    return "Hola " . params->{name};
};

get '/page' => sub {
    return $tmpl->template;
};

ajax '/page' => sub {

    my $parser           = Mojito::Page::Parse->new( page => params->{content} );
    my $page_struct      = $parser->page_structure;
    my $render           = Mojito::Page::Render->new;
    my $rendered_content = $render->render_body($page_struct);
    my $response_href    = { rendered_content => $rendered_content };
    to_json($response_href);
};

post '/page_org' => sub {

    my $parser           = Mojito::Page::Parse->new( page => params->{content} );
    my $page_struct      = $parser->page_structure;
    my $render           = Mojito::Page::Render->new;
    my $rendered_content = $render->render_body($page_struct);
    my $response_href    = { rendered_content => $rendered_content };
    my $JSON_response    = JSON::encode_json($response_href);
    if ( request->is_ajax ) {

        # create xml, set headers to text/xml, blablabla
        header( 'Content-Type'  => 'application/json' );
        header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );

        #to_json($response_href);
        return $JSON_response;
    }
    else {
        return $rendered_content;
    }
};


dance;
