package Mojito::Page::CRUD;
use MongoDB::OID;
use strictures 1;
use 5.010;
use Moo;
use Data::Dumper::Concise;

with('DBRole');

# Create
sub create {
    my ( $self, $page_struct ) = @_;

    # add save time as last_modified and created
    $page_struct->{last_modified} = $page_struct->{created} = time();

    #say "creating page at: ", time();
    my $id = $self->collection->insert($page_struct);
    return $id->value;
}

# Retrieve
sub read {
    my ( $self, $id ) = @_;
    my $oid = MongoDB::OID->new( value => $id );
    return $self->collection->find_one( { _id => $oid } );
}

# Update
sub update {
    my ( $self, $id, $page_struct ) = @_;

    my $oid = MongoDB::OID->new( value => $id );
    $page_struct->{last_modified} = time();

    #say "CRUD updating page at: ", time();
    $self->collection->update( { '_id' => $oid }, $page_struct );
}

# Delete
sub delete {
    my ( $self, $id ) = @_;

    my $oid = MongoDB::OID->new( value => $id );
    $self->collection->remove( { '_id' => $oid } );
}

# returns a MongoDB cursor one can iterate over.
sub get_all {
    my $self = shift;
    return $self->collection->find;
}

sub get_most_recent_docs {
    my $self = shift;
    return $self->collection->find->sort( { last_modified => -1 } );
}

sub get_most_recent_ids {
    my ($self) = @_;
    my $cursor = $self->get_most_recent;
    my @ids;
    while ( my $doc = $cursor->next ) {
        push @ids, $doc->{'_id'};
    }
    return \@ids;
}

# TODO: There's HTML in here, omg.
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

sub get_most_recent_links {
    my ($self, $want_delete_link) = @_;
    
    my $link_data = $self->get_most_recent_link_data;
    my $links = '<b>Recent Articles</b><br />';
    foreach my $datum (@{$link_data}) {
        $links .= '<a href="/page/' . $datum->{id} . '">' . $datum->{title} . "</a>";
        if ($want_delete_link) {
            $links .=  ' | <a id="page_delete" href="/page/'   . $datum->{id} . '/delete"> delete</a>';
        }
        $links .= "<br />\n";
    }
    return $links;
}

1
