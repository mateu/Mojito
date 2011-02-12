use strictures 1;
use 5.010;
package Shortcuts;

my @shortcuts = (\&cpan_URL);

sub expand_shortcuts {
    my $content = shift;
    foreach my $shortcut (@shortcuts) {
        $content = $shortcut->($content);
    }
    return $content;
}

sub cpan_URL {
    my ($content) = @_;
    return if !$content;
    
    $content =~ s/{{cpan\s+(.*)?}}/<a href="http:\/\/search.cpan.org\/perldoc?$1">$1<\/a>/i;
    return $content;
}


1