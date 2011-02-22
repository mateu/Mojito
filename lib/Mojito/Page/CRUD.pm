use strictures 1;
package Mojito::Page::CRUD;
use MongoDB::OID;
use 5.010;
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB');

=head1 Methods

=head2 create

Create a page in the database.

=cut

sub create {
    my ( $self, $page_struct ) = @_;

    # add save time as last_modified and created
    $page_struct->{last_modified} = $page_struct->{created} = time();

    #say "creating page at: ", time();
    my $id = $self->collection->insert($page_struct);
    return $id->value;
}

=head2 read

Read a page from the database.

=cut

sub read {
    my ( $self, $id ) = @_;
    my $oid = MongoDB::OID->new( value => $id );
    return $self->collection->find_one( { _id => $oid } );
}

=head2 update

Update a page in the database.

=cut

sub update {
    my ( $self, $id, $page_struct ) = @_;

    my $oid = MongoDB::OID->new( value => $id );
    $page_struct->{last_modified} = time();

    #say "CRUD updating page at: ", time();
    $self->collection->update( { '_id' => $oid }, $page_struct );
}

=head2 delete

Delete a page from the database.

=cut

sub delete {
    my ( $self, $id ) = @_;

    my $oid = MongoDB::OID->new( value => $id );
    $self->collection->remove( { '_id' => $oid } );
}

=head2 get_all

Get all pages in the notes collection.
Returns a MongoDB cursor one can iterate over.

=cut

sub get_all {
    my $self = shift;
    return $self->collection->find;
}

=head2 get_most_recent_docs

Get the documents sorted by date in reverse chrono order.

=cut

sub get_most_recent_docs {
    my $self = shift;
    return $self->collection->find->sort( { last_modified => -1 } );
}

=head2 get_most_recent_ids

Get just the ids of the documents sorted by date in reverse chrono order.

=cut

sub get_most_recent_ids {
    my ($self) = @_;
    my $cursor = $self->get_most_recent;
    my @ids;
    while ( my $doc = $cursor->next ) {
        push @ids, $doc->{'_id'};
    }
    return \@ids;
}

=head2 get_most_recent_link_data

Get the recent links data structure - ArrayRef[HashRef]

TODO: There's HTML in here, omg.

=cut

sub get_most_recent_link_data {
    my ($self) = @_;

    my $cursor = $self->get_most_recent_docs;
    my $link_data;
    while ( my $doc = $cursor->next ) {
        my $title = $doc->{title} || 'no title';
        push @{$link_data}, { id => $doc->{'_id'}->value, title => $title };
    }

    return $link_data;
}

=head2 get_most_recent_links

Turn the data into HTML

=cut

sub get_most_recent_links {
    my ($self, $want_delete_link, $base_url) = @_;
    
    my $link_data = $self->get_most_recent_link_data;
    my $links = '<b>Recent Articles</b><br />';
    foreach my $datum (@{$link_data}) {
        $links .= "<a href=\"${base_url}/page/" . $datum->{id} . '">' . $datum->{title} . "</a>";
        if ($want_delete_link) {
            $links .=  " | <a id=\"page_delete\" href=\"${base_url}/page/"   . $datum->{id} . '/delete"> delete</a>';
        }
        $links .= "<br />\n";
    }
    return $links;
}

1
