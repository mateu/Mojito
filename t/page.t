use strictures 1;
use Test::More;
use Mojito::Page;

my $pager = Mojito::Page->new( page => '<section>Full of Love</section>' );
isa_ok($pager, 'Mojito::Page');
my $page_struct = $pager->page_structure;
is(ref($page_struct), 'HASH', 'page struct is a HashRef');

done_testing();
