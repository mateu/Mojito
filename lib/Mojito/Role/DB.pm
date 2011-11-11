use strictures 1;
package Mojito::Role::DB;
use Moo::Role;
use Mojito::Model::Config;

my $doc_storage = ucfirst lc Mojito::Model::Config->new->config->{document_storage};
my $Role = __PACKAGE__ . '::' . $doc_storage;
with($Role);

1;