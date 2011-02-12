#!/usr/bin/env perl
use Dancer;
use Dancer ':syntax';
use Dancer::Plugin::Ajax;
#use Simple;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../../../dev/Mojito/lib";
use lib __DIR__ . "/../../../dev/Mojito/t/data";
use Fixture;
use PageParse;
use PageCRUD;
use PageRender;
use Template;
use JSON;

my $tmpl = Template->new;

#set 'logger' => 'console';
#set 'log' => 'debug';
#set 'show_errors' => 1;
#set 'access_log' => 1;
#set 'warnings' => 1;


our $VERSION = '0.1';

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

    my $parser           = PageParse->new( page => params->{content} );
    my $page_struct      = $parser->page_structure;
    my $render           = PageRender->new;
    my $rendered_content = $render->render_body($page_struct);
    my $response_href    = { rendered_content => $rendered_content };
    to_json($response_href);
};

post '/page_org' => sub {

    my $parser           = PageParse->new( page => params->{content} );
    my $page_struct      = $parser->page_structure;
    my $render           = PageRender->new;
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


get '/bench' => sub {

    my $parser      = PageParse->new( page => $Fixture::prettyprint );
    my $page_struct = $parser->page_structure;
    my $editer      = PageCRUD->new;
    my $id = '4d4a3e6769f174de44000000';
    my $page        = $editer->read($id);
    my $render      = PageRender->new;
    my $rendered_content = $render->render_body($page_struct);

    #    if ( request->is_ajax ) {
    #        # create xml, set headers to text/xml, blablabla
    #        header( 'Content-Type'  => 'application/json' );
    #        header( 'Cache-Control' => 'no-store, no-cache, must-revalidate' );
    #        my $response_href = { rendered_content => $rendered_content };
    #        my $JSON_response = JSON::encode_json($response_href);
    #        #to_json($response_href);
    #        return $JSON_response;
    #    }
    #    else {
    return $rendered_content;

    #    }
};

dance;
