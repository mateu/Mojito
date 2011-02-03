use strictures 1;
use 5.010;
use Test::More;
use Test::Differences;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use PageParse;
use Data::Dumper::Concise;

my $parser = PageParse->new(page => $Fixture::implicit_normal_starting_section);
my $sections = $parser->sections;
is_deeply($sections, $Fixture::sections, 'build sections');

done_testing();