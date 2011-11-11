use strictures 1;
package Mojito::Model::Doc;
use Mojito::Model::Doc::Mongo;
use Mojito::Model::Doc::Deep;
use Moo;
use Data::Dumper::Concise;

has 'doc' => (
    is => 'ro',
    lazy => 1,
    writer => '_set_doc',
    handles =>  [ qw( get_most_recent_docs get_feed_docs get_collections get_collection_pages) ],
);

sub BUILD {
    my ($self, $constructor_args_href) = @_;
    
    # Determine the document store backend from the configuration
    my $doc_storage = ucfirst lc $constructor_args_href->{config}->{document_storage};
    my $delegatee = __PACKAGE__ . '::' . $doc_storage;
    $self->_set_doc($delegatee->new($constructor_args_href));
}

1;