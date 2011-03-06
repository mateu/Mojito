#!/usr/bin/env perl
use Web::Simple 'MojitoApp';
use Mojito;
use JSON;

use Data::Dumper::Concise;

{
    package MojitoApp;
    use Plack::Builder;
    use Mojito::Auth;
    
    sub dispatch_request {
        my ( $self, $env ) = @_;
        my $mojito = $env->{mojito};

        # A Benchmark URI
        sub (GET + /bench ) {
            my ($self) = @_;
            
            my $rendered_content = $mojito->bench;

            [ 200, [ 'Content-type', 'text/html' ], [$rendered_content] ];
          },

          # PRESENT CREATE Page Form
          sub (GET + /page ) {
            my ($self) = @_;

            my $output = $mojito->fillin_create_page;

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # CREATE New Page, redirect to Edit Page mode
          sub (POST + /page + %* ) {
            my ( $self, $params ) = @_;

            my $redirect_url = $mojito->create_page($params);

            [ 301, [ Location => $redirect_url ], [] ];
          },

          # VIEW a Page
          sub (GET + /page/* ) {
            my ( $self, $id ) = @_;

            my $rendered_page = $mojito->view_page( { id => $id } );

            [ 200, [ 'Content-type', 'text/html' ], [$rendered_page] ];
          },

          # LIST Pages in chrono order
          sub (GET + /recent ) {
            my ($self) = @_;

            my $want_delete_link = 1;
            my $links = $mojito->get_most_recent_links($want_delete_link);

            [ 200, [ 'Content-type', 'text/html' ], [$links] ];
          },

          # PREVIEW Handler (and will save if save button is pushed).
          sub (POST + /preview + %*) {
            my ( $self, $params ) = @_;

            my $response_href = $mojito->preview_page($params);
            my $JSON_response = JSON::encode_json($response_href);

            [ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
          },

          # Present UPDATE Page Form
          sub (GET + /page/*/edit ) {
            my ( $self, $id ) = @_;

            my $output = $mojito->edit_page_form( { id => $id } );

            [ 200, [ 'Content-type', 'text/html' ], [$output] ];
          },

          # UPDATE a Page
          sub (POST + /page/*/edit + %*) {
            my ( $self, $id, $params ) = @_;

            $params->{id} = $id;
            my $redirect_url = $mojito->update_page($params);
            
            return [ 301, [ Location => $redirect_url ], [] ];
          },

          # DELETE a Page
          sub (GET + /page/*/delete ) {
            my ( $self, $id ) = @_;
            return [ 301, [ Location => $mojito->delete_page({id => $id}) ], [] ];
          },

          sub (GET + /hola/* ) {
            my ( $self, $name ) = @_;
            [ 200, [ 'Content-type', 'text/plain' ], ["Ola $name"] ];
          },

          sub (GET + /) {
            my ($self) = @_;

            my $output = $mojito->home_page;
            my $links = $mojito->get_most_recent_links;
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
    
    # Wrap in middleware here.
    around 'to_psgi_app', sub {
        my ($orig, $self) = (shift, shift);
        my $app = $self->$orig(@_); 
        builder {
            enable "+Mojito::Middleware";
           # enable "Auth::Basic", authenticator => \&Mojito::Auth::authen_cb;
            enable "Auth::Digest", 
              realm => "Mojito", 
              secret => Mojito::Auth::_secret,
              password_hashed => 1,
              authenticator => Mojito::Auth->new->digest_authen_cb;
            $app;
        };
    };
}

MojitoApp->run_if_script;
