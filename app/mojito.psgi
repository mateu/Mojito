#!/usr/bin/env perl

use Web::Simple 'MojitoApp';
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use Mojito;
use Mojito::Page;
use Mojito::Page::CRUD;
use JSON;

use Data::Dumper::Concise;

{

    package MojitoApp;
    my $mojito = Mojito->new;
    my $editer = Mojito::Page::CRUD->new;

    sub dispatch_request {
        my ($self, $env) = @_;
        my $base_url = $env->{SCRIPT_NAME}||'/';
        # make sure the base url ends with a slash
        $base_url =~ s/([^\/])$/$1\//;
        # pass base url to template since we need it there for link generation
        $mojito->base_url($base_url);
        my $pager  = Mojito::Page->new({
            page     => '<sx>Mojito page</sx>',
            base_url => $base_url,
        });

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

            my $output   = $pager->fillin_create_page;

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # CREATE New Page, redirect to Edit Page mode
          sub (POST + /page + %* ) {
            my ( $self, $params ) = @_;

            warn "Create Page";
            my $id = $mojito->create_page($params);
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
            my $output = $pager->fillin_edit_page( $source, $rendered_content, $id );

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # UPDATE a Page
          sub (POST + /page/*/edit + %*) {
            my ( $self, $id, $params ) = @_;

            $params->{id} = $id;
            my $page = $mojito->update_page($params);

            # If 'Done' button was pushed let's go to view
            if ( $params->{submit} eq 'Done' ) {
                my $redirect_url = "${base_url}page/${id}";
                return [ 301, [ Location => $redirect_url ], [] ];
            }

            my $source           = $page->{page_source};
            my $rendered_content = $pager->render_body($page);
            my $output = $pager->fillin_edit_page( $source, $rendered_content, $id );

            return [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # DELETE a Page
          sub (GET + /page/*/delete ) {
            my ( $self, $id ) = @_;
            
            $pager->delete($id);
            
            return [ 301, [ Location => '/recent' ], [] ];
          },

          sub (GET + /hola/* ) {
            my ( $self, $name ) = @_;
            [ 200, [ 'Content-type', 'text/plain' ], ["Ola $name"] ];
          },

          sub (GET + /) {
            my ($self) = @_;

            my $output   = $pager->home_page;
            my $links    = $pager->get_most_recent_links( 0, $base_url );
            $output =~
s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          sub (GET) {
            [ 200, [ 'Content-type', 'text/plain' ], ['Hola world!'] ];
          },

          sub () {
            [ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
          },

    }
}

MojitoApp->run_if_script;
