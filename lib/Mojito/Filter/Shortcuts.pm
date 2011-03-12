use strictures 1;
package Mojito::Filter::Shortcuts;
use 5.010;

my @shortcuts = (\&cpan_URL);

=head1 Methods

=head2 expand_shortcuts

Expand the available shortcuts into the content.

=cut

sub expand_shortcuts {
    my $content = shift;
    foreach my $shortcut (@shortcuts) {
        $content = $shortcut->($content);
    }
    return $content;
}

=head2 cpan_URL

Expand the cpan abbreviated shortcut.

=cut

sub cpan_URL {
    my ($content) = @_;
    return if !$content;

    $content =~ s/{{cpan\s+([^}]*)}}/<a href="http:\/\/search.cpan.org\/perldoc?$1">$1<\/a>/sig;
    return $content;
}


1