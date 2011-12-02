use strictures 1;
package Mojito::Page::CRUD;
use Mojito::Page::CRUD::Mongo;
use Mojito::Page::CRUD::Deep;
use Moo;

has 'editer' => (
    is => 'ro',
    lazy => 1,
    writer => '_set_editer',
    handles =>  [ qw( create read update delete db collection get_all ) ],
);

has 'config' => ( is => 'ro', required => 1);

sub BUILD {
    my ($self, $constructor_args_href) = @_;
    
    # Determine the document store backend from the configuration
    my $doc_storage = ucfirst lc $constructor_args_href->{config}->{document_storage};
    my $delegatee = __PACKAGE__ . '::' . $doc_storage;
    $self->_set_editer($delegatee->new($constructor_args_href));
}

1;
