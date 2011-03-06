use strictures 1;
package Mojito::Auth;
use Moo;
use Digest::MD5;
use Mojito::Types;

use Data::Dumper::Concise;

with 'Mojito::Role::DB';

=head1 Attributes

=cut

has 'username' => (
    is => 'ro',
    isa => Mojito::Types::NoRef,
);
has 'realm' => (
    is => 'ro',
    isa => Mojito::Types::NoRef,
);
has 'password' => (
    is => 'ro',
    isa => Mojito::Types::NoRef,
);
has 'env' => (
    is => 'ro',
    isa => Mojito::Types::NoRef,
);
has 'digest_authen_cb' => (
    is => 'ro',
    isa => Mojito::Types::CodeRef,
    lazy => 1,
    builder => '_build_digest_authen_cb',
);


=head1 Methods

=head2 authen_cb

The authentication callback used by Plack::Middleware::Authen::Basic.

=cut

sub authen_cb {
    my ( $username, $password ) = @_;
    return $password eq get_password_for($username);
}

=head2 _build_digest_authen_cb

The authentication callback used by Plack::Middleware::Authen::Digest.

=cut

sub _build_digest_authen_cb {
    my ($self) = @_;
    my $coderef = sub {
        my ($username, $env) = @_;
        return $self->get_HA1_for($username);
    };
    return $coderef; 
}

=head2 get_password_for

Given a username, return their password.

=cut

sub get_password_for {
    my ( $self, $username ) = @_;
    my $user = $self->collection->find_one( { username => $username } );
    return $user->{password};
}

=head2 get_HA1_for

Given a username, return their password.

=cut

sub get_HA1_for {
    my ( $self, $username ) = @_;
    my $user = $self->collection->find_one( { username => $username } );
    return $user->{HA1};
}

=head2 add_user

Provide the username, realm (default Mojito) and password.

=cut

sub add_user {
    my ( $self ) = @_;
   
    my @digest_input_parts = qw/ username realm password /;  
    my $digest_input = join ':', map {$self->$_} @digest_input_parts;
    my $HA1          = Digest::MD5::md5_hex($digest_input);
    my $md5_password = Digest::MD5::md5_hex($self->password);
    my $id = $self->collection->insert(
        {
            username => $self->username,
            realm    => $self->realm,
            HA1      => $HA1,
            password => $md5_password
        }
    );
    return $id;
}

=head2 secret

Used by Plack::Middleware::Auth::Digest

=cut

sub _secret () { ## no critic
    'més_vi_si_us_plau';
}

=head2 BUILD

Set some things post object construction, pre object use.

=cut

sub BUILD {
    my $self = shift;

    # We use the users collection for Auth stuff.
    $self->collection_name('users');
}

1
