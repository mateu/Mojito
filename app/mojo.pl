#!/usr/bin/env perl
use Mojolicious::Lite;
use lib '../lib';
use Mojito;
use Mojito::Auth;
use Plack::Builder;
use Data::Dumper::Concise;
use JSON;

# Make a shortcut the the mojito app object
app->helper( mojito => sub {
    return $_[0]->req->env->{mojito};
});

get '/bench' => sub {
    $_[0]->render( text => $_[0]->mojito->bench );
};

get '/hola/:name' => sub {
    $_[0]->render( text => "Hola " . $_[0]->param('name') );
};

get '/page' => sub {
    $_[0]->render( text => $_[0]->mojito->fillin_create_page );
};

post '/page' => sub {
    $_[0]->redirect_to(
        $_[0]->mojito->create_page( $_[0]->req->params->to_hash ) );
};

post '/preview' => sub {
    $_[0]->render(
        json => $_[0]->mojito->preview_page( $_[0]->req->params->to_hash )
    );
};

get '/page/:id' => sub {
    $_[0]->render( text =>
          $_[0]->mojito->view_page( { id => $_[0]->param('id') } )
    );
};

get '/public/page/:id' => sub {
    $_[0]->render( text =>
          $_[0]->mojito->view_page_public( { id => $_[0]->param('id') } )
    );
};

get '/page/:id/edit' => sub {
    $_[0]->render( text => $_[0]->mojito->edit_page_form( { id => $_[0]->param('id') } ) );
};

post '/page/:id/edit' => sub {

    # $self->req->params doesn't include placeholder $self->param() 's
    my $params = $_[0]->req->params->to_hash;
    $params->{'id'} = $_[0]->param('id');

    $_[0]->redirect_to($_[0]->mojito->update_page($params));
};

get '/page/:id/delete' => sub {
    $_[0]->redirect_to( $_[0]->mojito->delete_page({ id => $_[0]->param('id') }) );
};

get '/recent' => sub {
    $_[0]->render( text => $_[0]->mojito->get_most_recent_links({want_delete_link => 1}) );
};

get '/' => sub {
    $_[0]->render( text => $_[0]->mojito->view_home_page );
};

get '/public/feed/:feed' => sub {
    $_[0]->render( text => $_[0]->mojito->get_feed_links($_[0]->param('feed')) );
};

builder {
    enable "+Mojito::Middleware";
    enable_if { $ENV{RELEASE_TESTING}; } "+Mojito::Middleware::TestDB";
    enable_if { $_[0]->{PATH_INFO} !~ m/^\/(?:public|favicon.ico)/ }
      "Auth::Digest",
      realm => "Mojito",
      secret => Mojito::Auth::_secret,
      password_hashed => 1,
      authenticator => Mojito::Auth->new->digest_authen_cb;
    app->start;
};
