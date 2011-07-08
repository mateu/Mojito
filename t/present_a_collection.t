use strictures 1;
use Test::More;
use Mojito::Collection::Present;

# Grab some current data
my $collection_id = '4e04e4d86ceecbde60000001';
my $page_id = '4e04e4176ceecbdf60000000';

my $presenter = Mojito::Collection::Present->new( 
    collection_id => $collection_id,
    page_id => $page_id,
);
isa_ok($presenter, 'Mojito::Collection::Present');

done_testing();
