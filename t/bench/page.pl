use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use Fixture;
use PageParse;
use PageRender;
use PageCRUD;
use Data::Dumper::Concise;

my $page = $Fixture::implicit_section;
my $page_struct = PageParse->new( page => $page )->page_structure;
my $editer = PageCRUD->new( db_name => 'bench' );

my $count = $ARGV[0] || 1000;

my $result = cmpthese(
    $count,
    {
        'parse' => sub {
            PageParse->new( page => $page )->page_structure;
        },
        'render' => sub { PageRender->new->render_page($page_struct) },
        'edit'   => sub {
            my $id = $editer->create($page_struct);
            my $page = $editer->read($id);
        },
    }
);

#my $result = timethis($count, sub { PageParse->new(page => $Fixture::implicit_section)->page_structure });
