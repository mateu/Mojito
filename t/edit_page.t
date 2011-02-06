use strictures 1;
use 5.010;
#use Test::More;
#use Test::Differences;
use FindBin qw($Bin);
use lib "$Bin/data";
use Fixture;
use PageParse;
use PageEdit;
use PageRender;
use Data::Dumper::Concise;
use Time::HiRes qw/ time /;

my $start = time;
my $parser = PageParse->new(page => $Fixture::implicit_section);
my $page_struct = $parser->page_structure;

my $editer = PageEdit->new;
#my $oid = $editer->page_save($page_struct);
#say "oid: $oid";
my $id = MongoDB::OID->new(value => '4d4a3e6769f174de44000000');
my $doc = $editer->page_get($id);
#say Dumper $doc;
say "title: ", $doc->{title};

#my $render = PageRender->new;
#my $page = $render->render_page($page_struct);
##print 'raw: ', Dumper $raw;
##print 'rendered: ', Dumper $rendered;
#say $page;
say "took: ", (time - $start);

#ok(1);
#done_testing();