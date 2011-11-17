use strictures 1;
package Mojito::Filter::Shortcuts;
use Moo::Role;
use MooX::Types::MooseLike qw(:all);
use 5.010;
use Data::Dumper::Concise;

with('Mojito::Role::Config');

has shortcuts => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_shortcuts',
);
sub _build_shortcuts {
    my $self = shift;
    my @shortcuts = qw( cpan_URL metacpan_module_URL metacpan_author_URL);
    push @shortcuts, 'fonality_ticket' if ($self->config->{fonality_ticket_url});
    return \@shortcuts;
}

=head1 Methods

=head2 expand_shortcuts

Expand the available shortcuts into the content.

=cut

sub expand_shortcuts {
    my ($self, $content) = (shift, shift);
    foreach my $shortcut ( @{$self->shortcuts} ) {
        $content = $self->${shortcut}(${content});
    }
    return $content;
}

=head2 cpan_URL

Expand the cpan abbreviated shortcut.

=cut

sub cpan_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/{{cpan\s+([^}]*)}}/<a href="http:\/\/search.cpan.org\/perldoc?$1">$1<\/a>/sig;
    return $content;
}

=head2 metacpan_module_URL

Expand the cpan abbreviated shortcut.

=cut

sub metacpan_module_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s|{{modmeta\s+([^}]*)}}|<a href="http://metacpan.org/module/$1">$1</a>|sig;
    return $content;
}
=head2 metacpan_module_URL

Expand the cpan abbreviated shortcut.

=cut

sub metacpan_author_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s|{{authmeta\s+([^}]*)}}|<a href="http://metacpan.org/author/$1">$1</a>|sig;
    return $content;
}
=head2 fonality_ticket

Expand the fonality ticket abbreviated shortcut.

=cut

sub fonality_ticket {
    my ($self, $content) = @_;
    return if !($content && $self->config->{fonality_ticket_url});
    my $url = $self->config->{fonality_ticket_url};
    $content =~ s/{{fontic\s+(\d+)[^}]*}}/<a href="${url}${1}">${1}<\/a>/sig;
    return $content;
}

1
