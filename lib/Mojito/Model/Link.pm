use strictures 1;
package Mojito::Model::Link;
use Moo;
use Mojito::Model::Doc;

has base_url => ( is => 'rw', );

has doc => (
    is      => 'ro',
    isa     => sub { die "Need a Doc Model object.  Have ref($_[0]) instead." unless $_[0]->isa('Mojito::Model::Doc') },
    lazy    => 1,
    handles => [
        qw(
          get_most_recent_docs
          get_feed_docs
          )
    ],
    writer => '_build_doc',
);
=head1 Methods

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
    my $link_title = '<span id="recent_articles_label" style="font-weight: bold;">Recent Articles</span><br />' . "\n";
    my $links = $self->create_list_of_links($link_data, $args) || "No Documents yet.  Get to <a href='${base_url}page'>writing!</a>";

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
        $links .= "<div class='list_of_links'><a href=\"${base_url}page/" . $datum->{id} . '">' . $datum->{title} . "</a></div>";
        if ($args && $args->{want_delete_link}) {
            $links .=  " | <a id=\"page_delete\" href=\"${base_url}page/"   . $datum->{id} . '/delete"> delete</a>';
        }
        $links .= "\n";
    }
    return $links;
}

=head2 BUILD

Create the handler objects

=cut

sub BUILD {
    my $self                  = shift;
    my $constructor_args_href = shift;

    # pass the options into the subclasses
    $self->_build_doc(Mojito::Model::Doc->new($constructor_args_href));
}

1