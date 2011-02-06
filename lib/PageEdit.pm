package PageEdit;
use strictures 1;
use 5.010;
use Moo;

with('DBRole');

# save a page structure to DB
sub page_save {
    my ($self, $page_struct) = @_;
    # add save time as last_modified
    $page_struct->{last_modified} = time();
    my $id = $self->documents->insert($page_struct);;
    return $id;
}

# returns a MongoDB object
sub page_get {
    my ($self, $oid) = @_;
    return $self->documents->find_one({_id => $oid});
}

# returns a MongoDB cursor one can iterate over.
sub page_get_all {
    my $self = shift;
    return $self->documents->find;
}

1