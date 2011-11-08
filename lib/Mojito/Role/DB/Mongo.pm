use strictures 1;
package Mojito::Role::DB::Mongo;
use Moo::Role;
use MongoDB;

# Create a database and get a handle on a users collection.
has 'conn' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_conn',
);
has 'db_name' => (
    is => 'rw',
    lazy => 1,
    default => sub { 'mojito' },
    clearer => 'clear_db_name',
);
has 'db' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_db',
    clearer => 'clear_db',
);
has 'collection' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_collection',
    clearer => 'clear_collection',
);
has 'collection_name' => (
    is => 'rw',
    lazy => 1,
    default => sub { 'notes' },
    clearer => 'clear_collection_name',
);
has 'db_host' => (
    is => 'ro',
    lazy => 1,
    default => sub { 'localhost:27017' },
);

sub _build_conn {
    MongoDB::Connection->new(host => $_[0]->db_host);
}

sub _build_db  {
    my $self = shift;
    my $db_name = $self->db_name;
    $self->conn->${db_name};
}
sub _build_collection  {
    my $self = shift;
    my $collection_name = $self->collection_name;
    $self->db->${collection_name};
}

=head1 Methods

=head2 BUILD

Set a test DB when RELEASE_TESTING

=cut

sub BUILD {
    my ($self) = (shift);
    $self->db_name('mojito_test') if $ENV{RELEASE_TESTING};
}
1;