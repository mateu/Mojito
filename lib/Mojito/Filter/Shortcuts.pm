use strictures 1;
package Mojito::Filter::Shortcuts;
use Moo::Role;
use MooX::Types::MooseLike qw(:all);
use Mojito::Model::MetaCPAN;
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
    my @shortcuts = qw( cpan_URL metacpan_module_URL metacpan_author_URL internal_URL cpan_recent_synopses cpan_synopsis);
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

has metacpan => (
    is => 'ro',
    lazy => 1,
    default => sub { Mojito::Model::MetaCPAN->new },
);

=head2 cpan_synopsis

Show the CPAN SYNOPSIS for a Perl Module

=cut

sub cpan_synopsis {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/{{synopsis\s+([^}]*)}}/$self->metacpan->get_synopsis_formatted($1, 'presentation')/esig;
    return $content;
}

=head2 cpan_recent_synopses

Show the synopses of the CPAN recent releases

NOTE: This needs to run before cpan_synopsis since it expands into cpan synopses.

=cut

sub cpan_recent_synopses {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/{{\s*recent_synopses\s*(\d+)\s*}}/$self->metacpan->get_recent_synopses($1)/esig;
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


=head2 internal_URL

Expand an internal URL

=cut

sub internal_URL {
    my ($self, $content) = @_;
    return if !$content;
    $content =~ s/\[\[([^\|]*)\|([^\]]*)\]\]/<a href="$1">$2<\/a>/sig;
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
