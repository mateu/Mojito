use strictures 1;
use Shortcuts;
use Data::Dumper::Concise;

my $content = '<section>With some <em>words</em> and a link shortcut: {{cpan MojoMojo}} for testing.</section>';
print Shortcuts::expand_shortcuts($content);

