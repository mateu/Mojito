#!/usr/bin/env perl

use Web::Simple 'Mojito';
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use PageParse;
use PageCRUD;
use PageRender;
use Template;
use JSON;

{

    package Mojito;
    my $render = PageRender->new;
    my $editer = PageCRUD->new;
    my $tmpl   = Template->new;
#    use Data::Dumper::Concise;

    sub dispatch_request {
        
                  # A Benchmark URI
          sub (GET + /bench ) {
            my ($self) = @_;
            my $parser = PageParse->new( page => $Fixture::implicit_section );
            my $page_struct      = $parser->page_structure;
            my $editer           = PageCRUD->new;
            my $id               = '4d56c014fbb0bcf24e000000';
            my $page             = $editer->read($id);
            my $render           = PageRender->new;
            my $rendered_content = $render->render_page($page_struct);
            [ 200, [ 'Content-type', 'text/html' ], [$rendered_content] ];
          },

#          sub (GET + /deploy/*) {
#            my ( $self, $deploy_location ) = @_;
#            warn "Deploying to location: $deploy_location";
#            my $env = $_[PSGI_ENV];
#
#            [ 200, [ 'Content-type', 'text/plain' ], ["Raison d'etre"] ];
#          },

          sub (GET + /hola/* ) {
            my ( $self, $name ) = @_;
            [ 200, [ 'Content-type', 'text/plain' ], ["Ola $name"] ];
          },

          # PRESENT CREATE Page Form
          sub (GET + /page ) {
            my ($self) = @_;

            warn "Create Form";
            my $output = $tmpl->template;

            # Set mojito preiview_url variable
            my ${base_url} = $_[PSGI_ENV]->{SCRIPT_NAME} || '/';
            $output =~
s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview'<\/script>/;

            # Take out view button and change save to create.
            $output =~ s/<input id="submit_view".*?>//;
            $output =~
              s/<input id="submit_save"(.*?>)/<input id="submit_create"$1/;
            $output =~ s/(id="submit_create".*?value=)"Save"/$1"Create"/i;

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # CREATE New Page, redirect to Edit Page mode
          sub (POST + /page + %* ) {
            my ( $self, $params ) = @_;

            warn "Create Page";

            #			warn "content: ", $params->{content};
            warn "submit type: ", $params->{submit};

            my $parser = PageParse->new( page => $params->{content} );
            my $page_struct = $parser->page_structure;
            $page_struct->{page_html} = $render->render_page($page_struct);
            $page_struct->{body_html} = $render->render_body($page_struct);
            $page_struct->{title} =
              $render->intro_text( $page_struct->{body_html} );
            warn "title: ", $page_struct->{title};
            my $id           = $editer->create($page_struct);
            my $redirect_url = "/page/${id}/edit";

            [ 301, [ Location => $redirect_url ], [] ];
          },

          # VIEW a Page
          sub (GET + /page/* ) {
            my ( $self, $id ) = @_;

            warn "View Page $id";
            my $page          = $editer->read($id);
            my $rendered_page = $render->render_page($page);

            [ 200, [ 'Content-type', 'text/html' ], [$rendered_page] ];
          },

          # LIST Pages in chrono order
          sub (GET + /recent ) {
            my ($self) = @_;

            my $links = $editer->get_most_recent_links();

            [ 200, [ 'Content-type', 'text/html' ], [$links] ];
          },

          # PREVIEW Handler (and will save if save button is pushed).
          sub (POST + /preview + %*) {
            my ( $self, $params ) = @_;

            #warn "posted content: ", $params->{content};
            warn "Preview..";
            warn "extra action: ", $params->{extra_action};
            my $parser = PageParse->new( page => $params->{content} );
            my $page_struct = $parser->page_structure;
            if (   ( $params->{extra_action} eq 'save' )
                && ( $params->{'mongo_id'} ) )
            {
                $page_struct->{page_html} = $render->render_page($page_struct);
                $page_struct->{body_html} = $render->render_body($page_struct);
                $page_struct->{title} =
                  $render->intro_text( $page_struct->{body_html} );
                warn "*** TITLE: ", $page_struct->{title};
                $editer->update( $params->{'mongo_id'}, $page_struct );
            }

            my $render           = PageRender->new;
            my $rendered_content = $render->render_body($page_struct);
            my $response_href    = { rendered_content => $rendered_content };
            my $JSON_response    = JSON::encode_json($response_href);
            [ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
          },

          # Present UPDATE Page Form
          sub (GET + /page/*/edit ) {
            my ( $self, $id, $other ) = @_;

            warn "Update Form for Page $id";
            my $page             = $editer->read($id);
            my $rendered_content = $render->render_body($page);
            my $source           = $page->{page_source};

            # write source and rendered content into their tags
            my $output =
              fillin_edit_page( $source, $rendered_content, $id,
                base_url( $_[PSGI_ENV] ) );

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # UPDATE a Page
          sub (POST + /page/*/edit + %*) {
            my ( $self, $id, $params ) = @_;

            warn "UPDATE Page $id";
            warn "submit value: ", $params->{submit};
            my $parser = PageParse->new( page => $params->{content} );
            my $page = $parser->page_structure;

            # Store rendered parts as well.  May as well until proven wrong.
            $page->{page_html} = $render->render_page($page);
            $page->{body_html} = $render->render_body($page);
            $page->{title}     = $render->intro_text( $page->{body_html} );
            warn "title is: ", $page->{title};

            # Save page
            $editer->update( $id, $page );

            # If view button was pushed let's go to view
            if ( $params->{submit} eq 'View' ) {
                warn "going to View for id: $id";
                my $redirect_url = "/page/${id}";

                return [ 301, [ Location => $redirect_url ], [] ];
            }

            my $source           = $page->{page_source};
            my $rendered_content = $render->render_body($page);
            my $output =
              fillin_edit_page( $source, $rendered_content, $id,
                base_url( $_[PSGI_ENV] ) );

            return [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # DELETE a Page
          sub (GET + /page/*/delete ) {
            my ( $self, $id, $other ) = @_;

            warn "Delete page $id";
            $editer->delete($id);

            return [ 301, [ Location => '/recent' ], [] ];
          },

          sub (GET) {
            [ 200, [ 'Content-type', 'text/plain' ], ['Hello world!'] ];
          },

          sub () {
            [ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
          }
    }

    sub fillin_edit_page {
        my ( $page_source, $page_view, $mongo_id, $base_url ) = @_;

        my $output = $tmpl->template;
        $output =~
s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview';<\/script>/s;
        $output =~ s/(<input id="mongo_id".*?value=)""/$1"${mongo_id}"/si;
        $output =~
s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${page_source}<\/textarea>/si;
        $output =~
s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${page_view}<\/section>/si;

        return $output;
    }

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

Mojito->run_if_script;
