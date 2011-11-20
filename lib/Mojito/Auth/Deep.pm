use strictures 1;
package Mojito::Auth::Deep;
use Moo;
use Mojito::Page::CRUD::Deep;
use List::Util qw/first/;

with('Mojito::Role::DB::Deep');

has editer => (
    is => 'ro',
    lazy => 1,
    default => sub { Mojito::Page::CRUD::Deep->new(collection_name => 'users') },
);

=head2 add_user

Provide the username, realm (default Mojito) and password.

=cut

sub add_user {
    my ($self, $args) = @_;

    my $username = $args->{username} || $self->username;
    if ($self->get_user($username)) {
        warn "Username '$username' already taken!";
        return;
    }
    my @digest_input_parts = qw/ username realm password /;
    my $digest_input       = join ':', map { $self->$_ } @digest_input_parts;
    my $HA1                = Digest::MD5::md5_hex($digest_input);
    my $md5_password       = Digest::MD5::md5_hex( $self->password );
    # TODO - Make sure backend support unique user names
    # For Mongo we can ensure an index, but a general technique is 
    # to check for existence of a username before attempting to add it.
    my $id = $self->editer->create(
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
    # If we don't have any users yet, the be somewhat graceful about it
    return if !$self->collection;

    # Get collection
    my $collection = $self->collection->export;
    my @users = values %{$collection};
    my $user = first {$_->{username} eq $username} @users;
    return $user;
}

=head2 remove_user

Remove a user from the database.

=cut

sub remove_user {
    my ( $self, $username ) = @_;
    $username //= $self->username;
    return if !$username;
    # Just in case we have multiple occurrences of the same user
    my $collection = $self->collection->export;
    my @users = values %{$collection};
    my @wanted_users = grep {$_->{username} eq $username} @users;
    my @wanted_ids = map {$_->{id} } @wanted_users;
    my $users_deleted = 0;
    foreach my $id (@wanted_ids) {
        delete $self->collection->{$id};
        $users_deleted++;
    }
    return $users_deleted;
}

# Apply the role after the (role) required interface is defined (get_user, add_user)
with('Mojito::Auth::Role');

=head2 BUILD

Set some things post object construction, pre object use.

=cut

sub BUILD {
    my $self = shift;

    # We use the users collection for Auth stuff
    $self->collection_name('users');
}

1;