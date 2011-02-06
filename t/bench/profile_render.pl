use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use Fixture;
use PageRender;

my $page_struct =$Fixture::page_structure;
PageRender->new->render_page($page_struct);

