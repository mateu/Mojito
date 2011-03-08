use strictures 1;
package Mojito::Page::CRUD;
use MongoDB::OID;
use 5.010;
use Moo;
use Data::Dumper::Concise;

with('Mojito::Role::DB');

has base_url => ( is => 'rw', );

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

=head2 get_feed_docs

Get the documents for a particular feed sorted by date in reverse chrono order.

=cut

sub get_feed_docs {
    my ($self, $feed) = @_;
    return $self->collection->find({feeds => $feed})->sort( { last_modified => -1 } );
}

=head2 get_most_recent_link_data

Get the recent links data structure - ArrayRef[HashRef]

TODO: There's HTML in here, omg.

=cut

sub get_most_recent_link_data {
    my ($self) = @_;
    my $cursor = $self->get_most_recent_docs;
    return $self->get_link_data($cursor);
}

=head2 get_feed_link_data

Get the data to create links for a particular feed.

=cut

sub get_feed_link_data {
    my ($self, $feed) = @_;
    my $cursor = $self->get_feed_docs($feed);
    return $self->get_link_data($cursor);
}

=head2 get_link_data

Given a cursor of documents then create the link data.

=cut

sub get_link_data {
    my ($self, $cursor) = @_;
    
    my $link_data;
    while ( my $doc = $cursor->next ) {
        my $title = $doc->{title} || 'no title';
        push @{$link_data}, { id => $doc->{'_id'}->value, title => $title };
    }

    return $link_data;
}

=head2 get_most_recent_links

Turn the data into HTML
$args should be a HashRef of options

=cut

sub get_most_recent_links {
    my ($self, $args) = @_;
    
    my $base_url = $self->base_url;
    
    my $link_data = $self->get_most_recent_link_data;
    my $link_title = '<span id="recent_articles_label" style="font-weight: bold;">Recent Articles</span><br />';
    my $links = $self->create_list_of_links($link_data, $args);

    return $link_title . $links;
}

=head2 get_feed_links

Get the links for the documents belonging to a particular feed.

=cut

sub get_feed_links {
    my ($self, $feed) = @_;
    
    my $link_data = $self->get_feed_link_data($feed);
    my $title = ucfirst($feed) . ' Articles';
    my $link_title = "<span class='feeds' style='font-weight: bold;'>$title</span><br />";
    my $links = $self->create_list_of_links($link_data, {want_public_link => 1});
    if ($links) {
        return $link_title . $links;
    }
    else {
        "The <em>$feed</em> feed is <b>empty</b>";
    }
}

=head2 create_list_of_links

Given link data (doc id and title) and possibly some $args then create hyperlinks

=cut

sub create_list_of_links {
    my ($self, $link_data, $args) = @_;
    
    my $base_url = $self->base_url;
    $base_url .= 'public/' if $args->{want_public_link};
    my $links;
    foreach my $datum (@{$link_data}) {
        $links .= "<a href=\"${base_url}page/" . $datum->{id} . '">' . $datum->{title} . "</a>";
        if ($args && $args->{want_delete_link}) {
            $links .=  " | <a id=\"page_delete\" href=\"${base_url}page/"   . $datum->{id} . '/delete"> delete</a>';
        }
        $links .= "<br />\n";
    }
    return $links;
}

1
