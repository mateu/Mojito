#!/usr/bin/env perl
use Dancer;
use Dancer::Plugin::Ajax;
use Mojito;
use Mojito::Auth;

use Data::Dumper::Concise;

#set 'log_path'  => '/tmp';
set 'logger'      => 'console';
set 'log'         => 'debug';
set 'show_errors' => 1;
set 'access_log'  => 1;
set 'warnings'    => 1;

set plack_middlewares => [
        [ "+Mojito::Middleware" ],
#        [ "Auth::Basic",   authenticator => \&Mojito::Auth::authen_cb ],
        [ "Auth::Digest", 
              realm => "Mojito", 
              secret => Mojito::Auth::_secret,
              password_hashed => 1,
              authenticator => Mojito::Auth->new->digest_authen_cb, ],
];

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

ajax '/preview' => sub {
    to_json( $mojito->preview_page(scalar params) );
};

get '/page/:id' => sub {
    return $mojito->view_page( {id => params->{id}} );
};

get '/page/:id/edit' => sub {
    return $mojito->edit_page_form( {id => params->{id}} );
};

post '/page/:id/edit' => sub {
    redirect $mojito->update_page(scalar params);
};

get '/page/:id/delete' => sub {
    redirect $mojito->delete_page( {id => params->{id}} );
};

get '/recent' => sub {
    return $mojito->get_most_recent_links({want_delete_link => 1});
};

get '/' => sub {
    return $mojito->view_home_page;
};

dance;
