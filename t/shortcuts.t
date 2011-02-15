use strictures 1;
use Mojito::Filter::Shortcuts;
use Data::Dumper::Concise;

my $content = '<section>With some <em>words</em> and a link shortcut: {{cpan MojoMojo}} for testing.</section>';
print Mojito::Filter::Shortucts::Shortcuts::expand_shortcuts($content);

