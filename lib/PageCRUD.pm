package PageCRUD;
use MongoDB::OID;
use strictures 1;
use 5.010;
use Moo;
use Data::Dumper::Concise;

with('DBRole');

# create a new page
sub create
{
	my ($self, $page_struct) = @_;

	# add save time as last_modified and created
	$page_struct->{last_modified} = $page_struct->{created} = time();
	say "creating page at: ", time();
	my $id = $self->collection->insert($page_struct);
	return $id;
}

# get a page (from the DB)
sub read
{
	my ($self, $id) = @_;

	my $oid = MongoDB::OID->new(value => $id);
	return $self->collection->find_one({ _id => $oid });
}

# modify a page
sub update
{
	my ($self, $id, $page_struct) = @_;

	my $oid = MongoDB::OID->new(value => $id);
	$page_struct->{last_modified} = time();
	say "updating page at: ", time();
	$self->collection->update({ '_id' => $oid }, $page_struct);
}

# delete a page
sub delete
{
	my ($self, $id) = @_;

	my $oid = MongoDB::OID->new(value => $id);
	$self->collection->remove({ '_id' => $oid });
}

# returns a MongoDB cursor one can iterate over.
sub get_all
{
	my $self = shift;
	return $self->collection->find;
}

sub get_most_recent_docs
{
	my $self = shift;
	return $self->collection->find->sort({ last_modified => -1 });
}

sub get_most_recent_ids
{
	my ($self) = @_;
	my $cursor = $self->get_most_recent;
	my @ids;
	while (my $doc = $cursor->next)
	{
		push @ids, $doc->{'_id'};
	}
	return \@ids;
}

sub get_most_recent_links
{
    my ($self) = @_;
    my $cursor = $self->get_most_recent_docs;
    my $links;
    while (my $doc = $cursor->next) {
        my $link= '<a href="/page/' . $doc->{'_id'} . '">' . $doc->{title} . '</a>';
        $links .= "$link<br />"; 
    }
    return $links;
}
1
