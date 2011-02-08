#!/usr/bin/env perl

use Web::Simple 'Mojito';
use Dir::Self;
use lib  __DIR__ . "/../lib";
use lib  __DIR__ . "/../t/data";
use Fixture;
use PageParse;
use PageEdit;
use PageRender;
use Template;
use MongoDB::OID;
use JSON;
use HTML::Zoom;

use Data::Dumper::Concise;

{

    package Mojito;

    sub dispatch_request {

        sub (GET + /hola/* ) {
            my ( $self, $name ) = @_;
            [ 200, [ 'Content-type', 'text/plain' ], ["Hola $name"] ];
          },

          sub (GET + /page ) {
            my ( $self, $oid ) = @_;
            [ 200, [ 'Content-type', 'text/html' ], [Template::edit_page] ];
          },

          sub (GET + /page/*/edit ) {
            my ( $self, $oid, $other ) = @_;
            my $editer = PageEdit->new;
#            my $id   = MongoDB::OID->new( value => '4d4a3e6769f174de44000000' );
            my $id   = MongoDB::OID->new( value => $oid );
            my $page = $editer->page_get($id);
            my $render           = PageRender->new;
            my $rendered_content = $render->render_body($page);
            my $source = $page->{page_source};
            my $output = HTML::Zoom
                ->from_html(Template::edit_page)
                ->select('#content')
                ->replace_content(\$source)
                ->select('#view_area')
                ->replace_content(\$rendered_content)
                ->to_html;
            
            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          sub (GET + /bench ) {
            my ($self) = @_;
            my $parser = PageParse->new( page => $Fixture::implicit_section );
            my $page_struct = $parser->page_structure;
            my $editer      = PageEdit->new;
            my $id   = MongoDB::OID->new( value => '4d4a3e6769f174de44000000' );
            my $page = $editer->page_get($id);
            my $render           = PageRender->new;
            my $rendered_content = $render->render_page($page_struct);
            [ 200, [ 'Content-type', 'text/html' ], [$rendered_content] ];
          }, 
          
          sub (POST + /page + %*) {
            my ( $self, $params ) = @_;
            my $parser           = PageParse->new( page => $params->{content} );
            my $page_struct      = $parser->page_structure;
            my $render           = PageRender->new;
            my $rendered_content = $render->render_page($page_struct);
            my $response_href    = { rendered_content => $rendered_content };
            my $JSON_response    = JSON::encode_json($response_href);
            [ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
          }, 
          sub (POST + /page/*/edit + %*) {
            my ( $self, $oid, $params ) = @_;
            my $parser           = PageParse->new( page => $params->{content} );
            my $page_struct      = $parser->page_structure;
            my $render           = PageRender->new;
            my $rendered_content = $render->render_page($page_struct);
            my $response_href    = { rendered_content => $rendered_content };
            my $JSON_response    = JSON::encode_json($response_href);
            [ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
          },
          sub (GET) {
            [ 200, [ 'Content-type', 'text/plain' ], ['Hello world!'] ];
          }, sub () {
            [ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
          }
    }

}

Mojito->run_if_script;
