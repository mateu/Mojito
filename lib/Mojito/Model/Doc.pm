use strictures 1;
package Mojito::Model::Doc;
use Moo;
use Mojito::Model::Config;

my $config = Mojito::Model::Config->new->config;
my $doc_storage = ucfirst lc $config->{document_storage};
my $parent_class = 'Mojito::Model::Doc::' . $doc_storage;

extends $parent_class;


1;