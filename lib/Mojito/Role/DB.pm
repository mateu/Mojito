use strictures 1;
package Mojito::Role::DB;
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
    default => sub { 'docs' },
);
has 'db' => (
    is => 'ro',
    lazy => 1,
    builder => '_build_db',
);
has 'collection' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->db->notes },
);


sub _build_conn {
    MongoDB::Connection->new;
}

sub _build_db  {
    my $self = shift;
    my $db_name = $self->db_name; 
    $self->conn->${db_name};
}

1;