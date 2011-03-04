#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojito;
use Plack::Builder;

my ( $mojito, $base_url );

app->hook(
    before_dispatch => sub {
        my $self = shift;
        $base_url = $self->req->url->base;
        if ( $base_url !~ m/\/$/ ) {
            $base_url .= '/';
        }
        $mojito = Mojito->new( base_url => $base_url );
    }
);

get '/bench' => sub {
    $_[0]->render( text => $_[0]->req->env->{mojito}->bench );
};

get '/hola/:name' => sub {
    $_[0]->render( text => "Hola " . $_[0]->param('name') );
};

get '/page' => sub {
    $_[0]->render( text => $_[0]->req->env->{mojito}->fillin_create_page );
};

post '/page' => sub {
    $_[0]->redirect_to(
        $_[0]->req->env->{mojito}->create_page( $_[0]->req->params->to_hash ) );
};

post '/preview' => sub {
    $_[0]->render( json =>
          $_[0]->req->env->{mojito}->preview_page( $_[0]->req->params->to_hash )
    );
};

get '/page/:id' => sub {
    $_[0]->render( text =>
          $_[0]->req->env->{mojito}->view_page( { id => $_[0]->param('id') } )
    );
};

get '/page/:id/edit' => sub {
    $_[0]->render( text => $_[0]->req->env->{mojito}
          ->edit_page_form( { id => $_[0]->param('id') } ) );
};

post '/page/:id/edit' => sub {

    # for whatever reason ->params doesn't include placeholder params
    my $params = $_[0]->req->params->to_hash;
    $params->{'id'} = $_[0]->param('id');

    $_[0]->redirect_to($_[0]->req->env->{mojito}->update_page($params));
};

get '/page/:id/delete' => sub {
    $_[0]->redirect_to( $_[0]->req->env->{mojito}->delete_page({ id => $_[0]->param('id') }) );
};

get '/recent' => sub {
    my $self             = shift;
    my $want_delete_link = 1;
    my $links            = $mojito->get_most_recent_links($want_delete_link);
    $self->render( text => $links );
};

get '/' => sub {
    my $self   = shift;
    my $output = $mojito->home_page;
    my $links  = $mojito->get_most_recent_links;
    $output =~
      s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    $self->render( text => $output );
};

builder {
    enable "+Mojito::Middleware";
    enable "Auth::Basic", authenticator => \&authen_cb;
    app->start;
};

sub authen_cb {
    my ( $username, $password ) = @_;
    use Mojito::Page;
    my $mojito = Mojito::Page->new;
    $mojito->editer->collection_name('users');
    use MongoDB::OID;
    my $oid = MongoDB::OID->new( value => 'hunter' );
    my $user =
      $mojito->editer->collection->find_one( { username => $username } );
    return $username eq 'hunter' && $password eq $user->{password};
}
