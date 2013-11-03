use strictures 1;
package Mojito::Role::DB::Elasticsearch;
use Moo::Role;
use Mojito::Model::Config;
use Elasticsearch;
use Data::Dumper::Concise;

with('Mojito::Role::DB::OID');

has 'db_name' => (
    is => 'rw',
    lazy => 1,
    # Set a test DB when RELEASE_TESTING
    default => sub { 
        $ENV{RELEASE_TESTING} 
          ?  'mojito_test' 
          : Mojito::Model::Config->new->config->{es_index}; 
    },
    clearer => 'clear_db_name',
);
has 'db' => (
    is => 'lazy',
    builder => sub { Elasticsearch->new(nodes => [$_[0]->db_host]) },
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
    is => 'lazy',
    builder => sub { 'localhost:9200' },
);

sub _build_collection  {
    my $self = shift;
    if (not defined $self->db) {
        $self->clear_db;
    }
    my $results = $self->db->search(
        index => $self->db_name, 
        type => $self->collection_name,
        body => {query => {match_all => {}}},
    );
    return $results;
}


1;
