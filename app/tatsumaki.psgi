### app.psgi
use Tatsumaki::Error;
use Tatsumaki::Application;
use Tatsumaki::HTTPClient;
use Tatsumaki::Server;
use JSON;

package MainHandler;
use parent qw(Tatsumaki::Handler);
use Data::Dumper::Concise;

sub get {
    my ($self) = @_;
    $self->write($self->request->env->{'mojito'}->view_home_page);
}

package HolaNameHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $name ) = @_;
    $self->write(
        "<html><head><tite>$name</title></head><body>Hola $name</body></html>");
}

package BenchHandler;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $name ) = @_;
    $self->write( $self->request->env->{'mojito'}->bench );
}

package CreatePage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = @_;
    $self->write( $self->request->env->{'mojito'}->fillin_create_page );
}

sub post {
    my ($self) = @_;
    my $redirect_url = $self->request->env->{'mojito'}->create_page( $self->request->parameters );
    $self->response->redirect($redirect_url);
}

package PreviewPage;
use parent qw(Tatsumaki::Handler);

sub post {
    my ($self) = @_;
    $self->response->content_type('application/json');
    $self->write(
        JSON::encode_json(
            $self->request->env->{'mojito'}
              ->preview_page( $self->request->parameters )
        )
    );
}

package ViewPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->write($self->request->env->{'mojito'}->view_page({ id => $id }));
}

package ViewPagePublic;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->write($self->request->env->{'mojito'}->view_page_public({ id => $id }));
}

package EditPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->write($self->request->env->{'mojito'}->edit_page_form({id => $id}));
}

sub post {
    my ( $self, $id ) = @_;

    my $params = $self->request->parameters;
    $params->{id} = $id;
    my $redirect_url = $self->request->env->{'mojito'}->update_page($params);
    
    $self->response->redirect($redirect_url);
}

package SearchPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $search_word ) = @_;
    $self->write($self->request->env->{'mojito'}->search({word => $search_word}));
}

package DiffPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    my $params;
    $params->{'id'} = $id;
    $self->write($self->request->env->{'mojito'}->view_page_diff($params));
}

package RecentPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = @_;
    my $links = $self->request->env->{'mojito'}->recent_links;
    $self->write($links);
}

package FeedPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self, $feed) = @_;
    my $links = $self->request->env->{'mojito'}->get_feed_links($feed);
    $self->write($links);
}

package DeletePage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ( $self, $id ) = @_;
    $self->response->redirect($self->request->env->{mojito}->delete_page({id => $id}));
}

package main;
use Plack::Builder;
use Mojito;
use Mojito::Auth;
use Data::Dumper::Concise;

my $app = Tatsumaki::Application->new(
    [
        '/'                  => 'MainHandler',
        '/hola/(\w+)'        => 'HolaNameHandler',
        '/bench'             => 'BenchHandler',
        '/recent'            => 'RecentPage',
        '/page/(\w+)/edit'   => 'EditPage',
        '/page/(\w+)/delete' => 'DeletePage',
        '/page/(\w+)'        => 'ViewPage',
        '/public/page/(\w+)' => 'ViewPagePublic',
        '/page'              => 'CreatePage',
        '/preview'           => 'PreviewPage',
        '/search/(\w+)'      => 'SearchPage',
        '/public/feed/(\w+)' => 'FeedPage',
    ]
);

builder {
    enable_if { $_[0]->{PATH_INFO} !~ m/^\/(?:public|favicon.ico)/ } 
      "Auth::Digest", 
      realm => "Mojito", 
      secret => Mojito::Auth::_secret,
      password_hashed => 1,
      authenticator => Mojito::Auth->new->digest_authen_cb;
    enable "+Mojito::Middleware";
    enable_if { $ENV{RELEASE_TESTING}; } "+Mojito::Middleware::TestDB";

    $app;
};

#return $app;
