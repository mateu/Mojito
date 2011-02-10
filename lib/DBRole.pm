package DBRole;
use Moo::Role;
use strictures 1;
use MongoDB;

# Create a database and get a handle on a users collection.
has 'conn' => (
    is => 'ro',
    lazy => 1,
    builder => 'build_conn',
);
has 'db' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->conn->docs },
);
has 'collection' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->db->notes },
);


sub build_conn {
    MongoDB::Connection->new;
}

1;