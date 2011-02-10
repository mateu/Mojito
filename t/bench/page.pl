use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use Fixture;
use PageParse;
use PageRender;
use PageCRUD;
use MongoDB::OID;

my $page = $Fixture::implicit_section;
my $page_struct = PageParse->new( page => $page )->page_structure;
my $editer = PageCRUD->new;

my $count = 10000;

my $result = cmpthese(
    $count,
    {
        'parse' => sub {
            PageParse->new( page => $page )->page_structure;
        },
        'render' => sub { PageRender->new->render_page($page_struct) },
        'edit'   => sub {
            my $id = $editer->create($page_struct);
            my $id   = MongoDB::OID->new( value => '4d4a3e6769f174de44000000' );
            my $page = $editer->read($id);
        },
    }
);

#my $result = timethis($count, sub { PageParse->new(page => $Fixture::implicit_section)->page_structure });
