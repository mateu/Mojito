use strictures 1;
use Test::More;
use Mojito::Filter::Shortcuts;

my $content = '<section>With some <em>words</em> and a link shortcut: {{cpan MojoMojo}} for testing.</section>';
$content = Mojito::Filter::Shortcuts::expand_shortcuts($content);
like($content, qr/<a href="http:\/\/search.cpan.org\/perldoc\?MojoMojo">MojoMojo<\/a>/, 'CPAN Link');

done_testing();