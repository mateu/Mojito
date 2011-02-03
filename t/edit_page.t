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

my $parser = PageParse->new(page => $Fixture::implicit_section);
my $page_struct = $parser->page_structure;

my $editer = PageEdit->new;
my $oid = $editer->page_save($page_struct);
#say "oid: $oid";
my $doc = $editer->page_get($oid);
#say Dumper $doc;

my $render = PageRender->new;
my $page = $render->render_page($doc);
#print 'raw: ', Dumper $raw;
#print 'rendered: ', Dumper $rendered;
say $page;

#ok(1);
#done_testing();