use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use Fixture;
use PageParse;
use PageRender;

my $page = $Fixture::implicit_section;
my $page_struct =
  PageParse->new( page => $page)->page_structure;
  
my $count = 1000;

my $result = cmpthese(
    $count,
    {
        'parse' => sub {
            PageParse->new(page => $page)->page_structure;
        },
        'render' => sub { PageRender->new->render_page($page_struct) },
    }
);

#my $result = timethis($count, sub { PageParse->new(page => $Fixture::implicit_section)->page_structure });
