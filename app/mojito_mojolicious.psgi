#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojito;
use Mojito::Page;

my $mojito = Mojito->new;
my ($pager, $base_url);

app->hook(before_dispatch => sub {
    my $self  = shift;
    $base_url = $self->req->url->base;
    if ($base_url !~ m/\/$/) {
        $base_url .= '/';
    }
    $mojito->base_url($base_url);
    $pager = Mojito::Page->new( page => '<sx>Mojito page</sx>', base_url => $base_url );
});


get '/bench' => sub {
    my $self        = shift;
    $self->render( text => $mojito->bench );
};

get '/hola/:name' => sub {
    my $self = shift;
    $self->render( text => "Hola " . $self->param('name') );
};

get '/page' => sub {
    my $self = shift;
    $self->render( text => $pager->fillin_create_page );
};

post '/page' => sub {
    my $self = shift;
    my $params = $self->req->params->to_hash;
    my $id = $mojito->create_page($params);
    $self->redirect_to("${base_url}page/${id}/edit");
};

post '/preview' => sub {
    my $self = shift;
    $self->render( json => $mojito->preview_page($self->req->params->to_hash) );
};

get '/page/:id' => sub {
    my $self = shift;
    $self->render( text => $mojito->view_page( {id => $self->param('id')} ) );
};

get '/page/:id/edit' => sub {
    my $self = shift;
    $self->render( text => $mojito->edit_page_form( {id => $self->param('id')} ) );
};

post '/page/:id/edit' => sub {
    my $self = shift;
    my $id = $self->param('id');
    my $params = $self->req->params->to_hash;
    # for whatever reason ->params doesn't include placeholder params
    $params->{'id'} = $id;
    my $page = $mojito->update_page($params);
    $self->redirect_to("${base_url}page/${id}");
};

get '/page/:id/delete' => sub {
    my $self = shift;
    my $id = $self->param('id');
    $pager->delete($id);
    $self->redirect_to($base_url . 'recent');
};

get '/recent' => sub {
    my $self = shift;
    my $want_delete_link = 1;
    my $links            = $pager->get_most_recent_links($want_delete_link);
    $self->render( text => $links );
};

get '/' => sub {
    my $self = shift;
    my $output = $pager->home_page;
    my $links  = $pager->get_most_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    $self->render( text => $output );
};

app->start;
