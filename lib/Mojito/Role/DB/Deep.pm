use strictures 1;
package Mojito::Role::DB::Deep;
use Moo::Role;
use Mojito::Model::Config;
use DBM::Deep;
use Data::Dumper::Concise;

with('Mojito::Role::DB::OID');

has 'db_name' => (
    is => 'rw',
    lazy => 1,
    default => sub { Mojito::Model::Config->new->config->{dbm_deep_filepath} },
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

sub _build_db  {
    return DBM::Deep->new($_[0]->db_name);
}
sub _build_collection  {
    my $self = shift;
    my $collection_name = $self->collection_name;
    $self->db->{$collection_name};
}

=head1 Methods

=head2 BUILD

Set a test DB when RELEASE_TESTING

=cut

sub BUILD {
    my ($self) = (shift);
    my $test_db = '/home/hunter/mojito_test.db';
    $self->db_name($test_db) if $ENV{RELEASE_TESTING};
}

1;