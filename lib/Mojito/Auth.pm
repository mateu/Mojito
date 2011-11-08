use strictures 1;
package Mojito::Auth;
use Moo;
use Mojito::Model::Config;

# Determine parent class based on configuration
extends 'Mojito::Auth::' . ucfirst lc Mojito::Model::Config->new->config->{document_storage};

1
