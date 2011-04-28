use strictures 1;

package Mojito::Page::Publish;
use Moo;
use WWW::Mechanize;

=pod

Starting with the ability to publish a Mojito page to a MojoMojo wiki.

NEED:
- MM base_url
- MM username/password
- MM page name (path)
- some content

=cut

with('Mojito::Role::DB');
with('Mojito::Role::Config');

has target_base_url => (
    is      => 'ro',
    default => sub { $_[0]->config->{MM_base_url} },
);
has user => (
    is      => 'ro',
    default => sub { $_[0]->config->{MM_user} },
);
has password => (
    is      => 'ro',
    default => sub { $_[0]->config->{MM_password} },
);
has source_page => ( is => 'rw', );
has target_page => ( is => 'rw', );
has content     => (
    is       => 'rw',
    required => 1,
);
has mech => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_mech',
);

sub _build_mech {
    my ( $self, )  = @_;
    my $mech       = WWW::Mechanize->new;
    my $base_url   = $self->target_base_url;
    my $login_page = $base_url . '.login';
    $mech->get($login_page);
    $mech->submit_form(
        form_number => 1,
        fields      => {
            login => $self->user,
            pass  => $self->password,
        }
    );
    return $mech;
}

=head1 Methods

=head2 publish

Get, Fillin and Post the Form for a Page

=cut

sub publish {
    my $self = shift;

    my $mech = $self->mech;
    $mech->get( $self->target_base_url . $self->target_page . '.edit' );
    $mech->form_with_fields('body');
    $mech->field( body => $self->content );
    $mech->click_button( value => 'Save' );
    return;
}

1
