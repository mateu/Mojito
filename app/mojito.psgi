#!/usr/bin/env perl

use Web::Simple 'MojitoApp';
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use Mojito;
use Mojito::Page;
use Mojito::Page::CRUD;
use Mojito::Template;
use JSON;

use Data::Dumper::Concise;

{

    package MojitoApp;
    my $mojito = Mojito->new;
    my $render = Mojito::Page::Render->new;
    my $editer = Mojito::Page::CRUD->new;
    my $pager  = Mojito::Page->new( page => '<sx>Mojito page</sx>' );
    my $tmpl   = Mojito::Template->new;

    sub dispatch_request {
        my ($self, $env) = @_;
        my $base_url = $env->{SCRIPT_NAME}||'/';
        # make sure the base url ends with a slash
        $base_url =~ s/[^\/]$/\//;
        $pager->base_url($base_url);
        warn "base_url: $base_url";

        # A Benchmark URI
        sub (GET + /bench ) {
            my ($self) = @_;
            my $pager = Mojito::Page->new( page => $Fixture::implicit_section );
            my $page_struct = $pager->page_structure;
            my $editer      = Mojito::Page::CRUD->new( db_name => 'bench' );
            my $id          = $editer->create($page_struct);
            my $rendered_content = $pager->render_page($page_struct);

            [ 200, [ 'Content-type', 'text/html' ], [$rendered_content] ];
          },

          # PRESENT CREATE Page Form
          sub (GET + /page ) {
            my ($self) = @_;

            my $output   = $tmpl->fillin_create_page($base_url);

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # CREATE New Page, redirect to Edit Page mode
          sub (POST + /page + %* ) {
            my ( $self, $params ) = @_;

            warn "Create Page";
            my $id = $mojito->create_page( {content => $params->{content} });
            my $redirect_url = "${base_url}page/${id}/edit";

            [ 301, [ Location => $redirect_url ], [] ];
          },

          # VIEW a Page
          sub (GET + /page/* ) {
            my ( $self, $id ) = @_;

            warn "View Page $id";
            my $page          = $pager->read($id);
            my $rendered_page = $pager->render_page($page);
            my $links         = $pager->get_most_recent_links( 0, $base_url );

            # Change class on view_area when we're in view mode.
            $rendered_page =~
s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
            $rendered_page =~
s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

            [ 200, [ 'Content-type', 'text/html' ], [$rendered_page] ];
          },

          # LIST Pages in chrono order
          sub (GET + /recent ) {
            my ($self) = @_;

            my $want_delete_link = 1;
            my $links = $pager->get_most_recent_links( $want_delete_link, $base_url );

            [ 200, [ 'Content-type', 'text/html' ], [$links] ];
          },

          # PREVIEW Handler (and will save if save button is pushed).
          sub (POST + /preview + %*) {
            my ( $self, $params ) = @_;

            my $response_href = $mojito->preview_page($params);
            my $JSON_response    = JSON::encode_json($response_href);
            
            [ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
          },

          # Present UPDATE Page Form
          sub (GET + /page/*/edit ) {
            my ( $self, $id, $other ) = @_;

            #warn "Update Form for Page $id";
            my $page             = $pager->read($id);
            my $rendered_content = $pager->render_body($page);
            my $source           = $page->{page_source};

            # write source and rendered content into their tags
            my $output = $tmpl->fillin_edit_page( $source, $rendered_content, $id, $base_url );

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # UPDATE a Page
          sub (POST + /page/*/edit + %*) {
            my ( $self, $id, $params ) = @_;

            #warn "UPDATE Page $id";
            #warn "submit value: ", $params->{submit};
            $params->{id} = $id;
            my $page = $mojito->update_page($params);

            # If view button was pushed let's go to view
            if ( $params->{submit} eq 'Done' ) {

                #warn "going to View for id: $id";
                my $redirect_url = "${base_url}page/${id}";

                return [ 301, [ Location => $redirect_url ], [] ];
            }

            my $source           = $page->{page_source};
            my $rendered_content = $pager->render_body($page);
            my $output = $tmpl->fillin_edit_page( $source, $rendered_content, $id, $base_url );

            return [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # DELETE a Page
          sub (GET + /page/*/delete ) {
            my ( $self, $id, $other ) = @_;

            warn "Delete page $id";
            $pager->delete($id);

            return [ 301, [ Location => '/recent' ], [] ];
          },

          sub (GET + /hola/* ) {
            my ( $self, $name ) = @_;
            [ 200, [ 'Content-type', 'text/plain' ], ["Ola $name"] ];
          },

          sub (GET + /) {
            my ($self) = @_;

            my $output   = $tmpl->home_page;
            my $links    = $pager->get_most_recent_links( 0, $base_url );
            $output =~
s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          sub (GET) {
            [ 200, [ 'Content-type', 'text/plain' ], ['Hello world!'] ];
          },

          sub () {
            [ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
          },

    }

    sub fillin_view_page { }

    sub base_url {
        my $env = shift;

        my $uri = $env->{SCRIPT_NAME} || '/';

        #          ($env->{'psgi.url_scheme'} || "http")
        #          . "://"
        #          . (
        #            $env->{HTTP_HOST}
        #              || (($env->{SERVER_NAME} || "")
        #              . " : "
        #              . ($env->{SERVER_PORT} || 80))
        #          ) . ($env->{SCRIPT_NAME} || '/');
        return $uri;
    }
}

MojitoApp->run_if_script;
