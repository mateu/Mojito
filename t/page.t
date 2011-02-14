use strictures 1;
use 5.010;
use Test::More;
use Mojito::Page;
use Data::Dumper::Concise;

my $pager = Mojito::Page->new( page => '<section>Full of Love</section>' );
isa_ok($pager, 'Mojito::Page');
my $page_struct = $pager->page_structure;
is(ref($page_struct), 'HASH', 'page struct is a HashRef');
#say $pager->render_page($page_struct);
my $page_id = '4d586981bd851b7c2a000000';
my $page = $pager->read($page_id);
#say Dumper $page;

done_testing();
