use strictures 1;
use 5.010;
use Test::More;
use Test::Differences;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use ParsePage;


my $parser = ParsePage->new(page => $Fixture::implicit_normal_starting_section);
my $sectioned_page = $parser->add_implicit_sections;
$parser->parse_html5($sectioned_page);


ok(1);
done_testing();