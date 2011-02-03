package DBRole;
use Moo::Role;
use strictures 1;
use 5.010;
use MongoDB;
use MongoDB::OID;
use Data::Dumper::Concise;

# Create a database and get a handle on a users collection.
has 'conn' => (
    is => 'ro',
    lazy => 1,
    builder => 'build_conn',
);
has 'notes' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->conn->notes },
);
has 'documents' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->notes->documents },
);


sub build_conn {
    MongoDB::Connection->new;
}

1;