use strictures 1;
use 5.010;
use Benchmark qw/ timethese cmpthese /;
use Data::Dumper::Concise;
use lib '/home/hunter/dev/Data-Skeleton/lib';
use Data::Skeleton;
my $ds = Data::Skeleton->new;

# Ramdisk did not affect the results, strange...
#use Sys::Ramdisk;
#my $ramdisk = Sys::Ramdisk->new(
#    size => "1m",
#    dir  => "/tmp/ramdisk",
#);
#
#$ramdisk->mount();

# Use ramdisk on /tmp/ramdisk ...

# Get a document
my $doc_id = '4e9ecf8a96c2b69132000000';
use Mojito::Page::CRUD;
use Mojito;
my $editer = Mojito::Page::CRUD->new;
my $mojito_page = $editer->read($doc_id);
my %mojito_page_copy = %{$mojito_page};
delete $mojito_page_copy{_id};
my $mojito_page_copy = \%mojito_page_copy;

my $count = $ARGV[0] || 5000;
my $doc_content =
  'Test value that has some sorta length to it beyond the trivial
    amount one might usually find in a simpleton hello world app
    amount one might usually find in a simpleton hello world app';

my $mongo_coderef = sub {
    my $doc = $editer->read($doc_id);
    $doc->{new_key} = $doc_content;

    $editer->update($doc_id, $doc);

    #    say "mongo:", Dumper $ds->deflesh($editer->read($doc_id));
};

# Deep Store
use DBM::Deep;
my $db_deep = DBM::Deep->new("/tmp/ramdisk/foo.db");
$mojito_page = $editer->read($doc_id);
my $mojito = Mojito->new;
my $db_value = {mojito => $mojito};
my $deep_coderef = sub {
    warn Dumper $db_value;
    $db_deep->{'foo_bar'} = { puta => [1, 3] }; 
#    my $doc = $db_deep->{$doc_id};
#    $doc->{new_key} = $doc_content;
#    my $page_struct = $db_deep->{$doc_id}->export;
#    my $mj = $db_deep->export->{$doc_id}->{mojito};
#    say "deep mojito: ", Dumper $mj;
   # say "deep editer: ", Dumper $editer;
   # my $pagina = $editer->read($doc_id);
    #say "deep: ", Dumper $pagina;
};

use Net::Riak::Bucket;
use Net::Riak;
my $client = Net::Riak->new()->client;
my $bucket = Net::Riak::Bucket->new(name => 'foo', client => $client);
my $riak_coderef = sub {

    #    my $doc = $editer->read($doc_id);
    my $doc_object = $bucket->get($doc_id);
    my $data       = $doc_object->data;
    delete $data->{_id};
    my $object = $bucket->new_object($doc_id, $data);
    $object->store;
};

use KyotoCabinet;
my $db_kyoto = new KyotoCabinet::DB;
# open the database
if (!$db_kyoto->open('casket.kch', $db_kyoto->OWRITER | $db_kyoto->OCREATE)) {
    printf STDERR ("open error: %s\n", $$db_kyoto->error);
}
use Data::MessagePack;
my $mp = Data::MessagePack->new();
my $kyoto_coderef = sub {

    # store records
    my $dat = $mojito_page_copy;
    $dat  = $mp->pack($dat);
    if (!$db_kyoto->set('foo', $dat)) {
        printf STDERR ("set error: %s\n", $db_kyoto->error);
    }
    # retrieve records
    my $value = $db_kyoto->get('foo');
    if (defined($value)) {
        my $unpacked = $mp->unpack($value);
#        printf("%s\n", $unpacked);
#        print "value: ", Dumper $unpacked;
    }
    else {
        printf STDERR ("get error: %s\n", $db_kyoto->error);
    }
};



cmpthese(
    $count,
    {
#        mongo => $mongo_coderef,
        deep  => $deep_coderef,
        #riak  => $riak_coderef,
#        kyoto => $kyoto_coderef,
    }
);

#say Dumper $ds->deflesh($page);

# Mojito MongoDB to Mojito DBM::Deep (and vice versa)
