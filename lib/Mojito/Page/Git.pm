use strictures 1;
package Mojito::Page::Git;
use 5.010;
use Moo;
use Git::Wrapper;
use IO::File;
use File::Spec;
use Data::Dumper::Concise;

with('Mojito::Role::DB');

has dir => (
    is        => 'rw',
    'default' => sub { '/home/hunter/tmp/repo-dir' },
);

has git => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_git',
);

sub _build_git {
    my $self = shift;
    return Git::Wrapper->new( $self->dir );
}

=head1 Methods

=head2 commit_page

Commit a page revision to the git repository.

=cut

sub commit_page {
    my ( $self, $page_struct, $page_id ) = @_;

    IO::File->new( ">" . File::Spec->catfile( $self->dir, $page_id ) )
      ->print($page_struct->{page_source});
    $self->git->add({}, ${page_id});
    $self->git->commit( { message => "Test".rand() }, $page_id );
}

=head2 diff_page

Get the diff between two versions of a page.

=cut

sub diff_page {
    my ( $self, $page_id ) = @_;

    warn "DIFF: for page: $page_id";
    my @diff = $self->git->diff({}, "HEAD^..HEAD", ${page_id});
    my $diff = join "\n", @diff;
    warn "DIFF: $diff";

    return $diff;
}

1
