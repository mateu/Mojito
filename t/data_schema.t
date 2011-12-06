use strictures 1;
use Test::More;
use Mojito::Page::CRUD;
use Mojito::Model::Config;
use Data::Schema;
use Data::Dumper::Concise;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

# Get a page to test the schema against
my $crud = Mojito::Page::CRUD->new(config => Mojito::Model::Config->new->config);
my ($page, $response);
my $all = $crud->get_all;
if (ref($all) eq 'MongoDB::Cursor') {
    $page = $all->next;
}
elsif (ref($all) eq 'HASH') {
    my (undef, $page) = each %{$all};
}
else {
    die 'Unknown ref for $all of ', ref($all);
}

my $mojito_schema = {
    def => {
        sxes => [array => {of => 
            [hash => { 
                required_keys => [qw/content class/],
                keys => {
                    content => 'str', 
                    class => 'str'
                }
            }]
        }],
        mojito => [ hash => {
            required_keys => [qw/sections/],
            'keys' => {
                sections => 'sxes',
                '_id'   => [object=> {isa_one => [qw/MongoDB::OID/]}],
                created  => 'int',
                last_modified  => 'int',
                page_source    => 'str',
                page_name      => 'str',
                title          => 'str',
                default_format => 'str',
                page_html      => 'str',
                body_html      => 'str', 
            }
        }],
    },
    type => 'mojito',
};

$response = ds_validate($page, $mojito_schema);
ok($response->{success}, 'DB Schema validates');
print "ERRORS: ", Dumper $response->{errors} if not $response->{success};

# Synthetic data
my $data = {
    _id => bless( {
        value => "4ecd8c4b73974a054e000000"
    }, 'MongoDB::OID' ),
    created        => "1",
    default_format => "textile",
    last_modified  => "2",
    page_name      => "deu",
    page_source    => "# Mr Big",
    sections       => [
        {
            class   => "implicit",
            content => "# Mr Big",
        },
    ],
    title => "Leaning Tower of Pizza",
};

$response = ds_validate($data, $mojito_schema);
ok($response->{success}, 'Synthetic Schema validates');
print "ERRORS: ", Dumper $response->{errors} if not $response->{success};

done_testing;