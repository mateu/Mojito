use strictures 1;
package Mojito::Role::DB;
use Moo::Role;
use Mojito::Model::Config;

my $parent_role = 'Mojito::Role::DB::' . ucfirst lc  Mojito::Model::Config->new->config->{document_storage};

with($parent_role);

1;