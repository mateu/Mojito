use strictures 1;
package Mojito::Page::CRUD;
use Moo;
use Mojito::Model::Config;

my $config = Mojito::Model::Config->new->config;
my $doc_storage = ucfirst lc $config->{document_storage};
my $parent_class = 'Mojito::Page::CRUD::' . $doc_storage;

extends $parent_class;


1;