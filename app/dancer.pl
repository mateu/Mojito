#!/usr/bin/env perl
use Dancer;
use Dancer::Plugin::Ajax;
use Plack::Builder;
use lib '../lib';
use Mojito;
use Mojito::Auth;

use Data::Dumper::Concise;

#set 'log_path'  => '/tmp';
set 'logger'      => 'console';
set 'log'         => 'debug';
set 'show_errors' => 1;
set 'access_log'  => 1;
#set 'warnings'    => 1;

# Provide a shortcut to the mojito object
my ($mojito);
before sub {
    $mojito = request->env->{mojito};
    var mojito => $mojito;
};

get '/bench' => sub {
    return $mojito->bench;
};

get '/hola/:name' => sub {
    return "Hola " . params->{name};
};

get '/page' => sub {
    return $mojito->fillin_create_page;
};

post '/page' => sub {
    redirect $mojito->create_page(scalar params);
};

post '/preview' => sub {
    to_json( $mojito->preview_page(scalar params) );
};

get '/page/:id' => sub {
    return $mojito->view_page( {id => params->{id}} );
};

get '/public/page/:id' => sub {
    return $mojito->view_page_public( {id => params->{id}} );
};

get '/page/:id/edit' => sub {
    return $mojito->edit_page_form( {id => params->{id}} );
};

post '/page/:id/edit' => sub {
    redirect $mojito->update_page(scalar params);
};

get '/search/:word' => sub {
    return $mojito->search(scalar params);
};

get '/page/:id/diff/:m/:n' => sub {
    return $mojito->diff_page(scalar params);
};

get '/page/:id/diff' => sub {
    return $mojito->view_page_diff(scalar params);
};

get '/page/:id/delete' => sub {
    redirect $mojito->delete_page( {id => params->{id}} );
};

get '/recent' => sub {
    return $mojito->recent_links;
};

get '/collect' => sub {
    return $mojito->collect_page_form(scalar params);
};

post '/collect' => sub {
    redirect $mojito->collect(scalar params);
};

get '/collection/:id' => sub {
    return $mojito->collection_page(scalar params);
};

get '/collections' => sub {
    return $mojito->collections_index;
};

get '/collection/:id/sort' => sub {
    return $mojito->sort_collection_form(scalar params);
};

post '/collection/:id/sort' => sub {
    redirect $mojito->sort_collection(scalar params);
};

post '/publish' => sub {
    to_json( $mojito->publish_page(scalar params) );
};

get '/' => sub {
    return $mojito->view_home_page;
};

get '/public/feed/:feed' => sub {
    return $mojito->get_feed_links(params->{feed});
};

builder {
    enable_if { $_[0]->{PATH_INFO} !~ m/^\/(?:public|favicon.ico)/ }
      "Auth::Digest",
      realm => "Mojito",
      secret => Mojito::Auth::_secret,
      password_hashed => 1,
      authenticator => Mojito::Auth->new->digest_authen_cb;
    enable "+Mojito::Middleware";
    enable_if { $ENV{RELEASE_TESTING}; } "+Mojito::Middleware::TestDB";

    dance;
};

