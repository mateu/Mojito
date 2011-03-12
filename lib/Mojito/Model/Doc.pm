use strictures 1;
package Mojito::Model::Doc;
use Moo;

with('Mojito::Role::DB');

=head1 Methods

=head2 get_most_recent_docs

Get the documents sorted by date in reverse chrono order.
Returns a cursor to them.

=cut

sub get_most_recent_docs {
    my $self = shift;
    return $self->collection->find->sort( { last_modified => -1 } );
}

=head2 get_feed_docs

Get the documents for a particular feed sorted by date in reverse chrono order.
Returns a cursor to them.

=cut

sub get_feed_docs {
    my ($self, $feed) = @_;
    return $self->collection->find({feeds => $feed})->sort( { last_modified => -1 } );
}

1