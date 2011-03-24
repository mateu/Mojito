use strictures 1;
package Mojito::Page::Git;
use 5.010;
use Moo;
use Git::Wrapper;
use IO::File;
use File::Spec;
use Try::Tiny;
use Data::Dumper::Concise;

with('Mojito::Role::DB');

has dir => (
    is        => 'rw',
    'default' => sub { '/home/hunter/repos/mojito' },
);

has git => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_git',
);

sub _build_git {
    my $self = shift;
    my $git = Git::Wrapper->new( $self->dir );
    $git->init;
    return $git;
}

=head1 Methods

=head2 commit_page

Commit a page revision to the git repository.

=cut

sub commit_page {
    my ( $self, $page_struct, $page_id ) = @_;

    my $file = File::Spec->catfile( $self->dir, $page_id ) 
      || die "Can't ->catfile on dir", $self->dir, " and page_id $page_id $@";
    my $io = IO::File->new( ">" . $file) || die "Can't create new IO::File for file: $file. $@"; 
    $io->print($page_struct->{page_source});

    return if !$self->git->status->is_dirty; 

    $self->git->add({}, ${page_id});
    $self->git->commit( { message => "Test".rand() }, $page_id );

    return;
}

=head2 rm_page

Remove a page from the repo (done when deleting a page from the DB)

=cut

sub rm_page {
    my ( $self, $page_id ) = @_;

    $self->git->rm({}, ${page_id});
    $self->git->commit( { message => "Delete page" }, $page_id );

}

=head2 diff_page

Get the diff between two versions of a page.

=cut

sub diff_page {
    my ( $self, $page_id ) = @_;

    my @diff = $self->git->diff({}, "HEAD^..HEAD", ${page_id});
    my $diff = join "\n", @diff;

    return $diff;
}

=head2 search_word 

Search for a word using git grep and return the list of matching document ids.
NOTE: A document can be returned more than once so we'll make hash of documents
with the count of how many times they matched.

=cut

sub search_word {
    my ($self, $search_word) = (shift, shift);
    warn "** Searching on $search_word";
    my @search_hits;
    my $no_hits = 0;
    try {
        @search_hits = $self->git->grep({'ignore_case' => 1}, $search_word); 
    }
    catch {
        $no_hits = 1;
    }; 
    return if $no_hits; 

    my @page_ids = map { my ($file) = $_ =~ /^(\w+)\:/; } @search_hits;
    my %hit_hash = ();
    %hit_hash = map { $_ => ++$hit_hash{$_}} @page_ids;
    return \%hit_hash;
}


1
