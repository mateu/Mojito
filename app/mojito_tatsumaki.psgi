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
    my $mojito = $self->request->env->{'mojito'};
    my $output = $mojito->home_page;
    my $links  = $mojito->get_most_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    $self->write($output);
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

package RecentPage;
use parent qw(Tatsumaki::Handler);

sub get {
    my ($self) = @_;

    my $want_delete_link = 1;
    my $links = $self->request->env->{'mojito'}->get_most_recent_links($want_delete_link);
    
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
        '/page'              => 'CreatePage',
        '/preview'           => 'PreviewPage',
    ]
);

builder {

    #    enable "Debug";
    enable "+Mojito::Middleware";
    enable "Auth::Basic", authenticator => \&authen_cb;
#    enable 'Session';
#    enable 'Auth::Form', authenticator => sub { 1 }; 
    
    $app;
};

sub authen_cb {
    my($username, $password) = @_;
    use Mojito::Page;
    my $mojito = Mojito::Page->new;
    $mojito->editer->collection_name('users');
    use MongoDB::OID;
    my $oid = MongoDB::OID->new( value => 'hunter' );
    my $user = $mojito->editer->collection->find_one( { username => $username } );
    return $username eq 'hunter' && $password eq $user->{password};
}
#return $app;
