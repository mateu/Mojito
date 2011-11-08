use strictures 1;
package Mojito::Auth::Mongo;
use Moo;

extends 'Mojito::Auth::Base';

=head1 Methods

=head2 add_user

Provide the username, realm (default Mojito) and password.

=cut

sub add_user {
    my ($self) = @_;

    my @digest_input_parts = qw/ username realm password /;
    my $digest_input       = join ':', map { $self->$_ } @digest_input_parts;
    my $HA1                = Digest::MD5::md5_hex($digest_input);
    my $md5_password       = Digest::MD5::md5_hex( $self->password );
    my $id                 = $self->collection->insert(
        {
            first_name => $self->first_name,
            last_name  => $self->last_name,
            email      => $self->email,
            username   => $self->username,
            realm      => $self->realm,
            HA1        => $HA1,
            password   => $md5_password
        }
    );
    return $id;
}

=head2 get_user

Get a user from the database.

=cut

sub get_user {
    my ( $self, $username ) = @_;
    $username //= $self->username;
    return if !$username;
    return $self->collection->find_one( { username => $username } );
}

1
