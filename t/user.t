use strictures 1;
use Test::More;
use Mojito::Auth;
use Mojito::Model::Config;
use Data::Dumper::Concise;
BEGIN {
    if (!$ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release testing');
    }
}

# Need config as a constructor arg for Auth
my $config = Mojito::Model::Config->new->config;
my $mojito_auth = Mojito::Auth->new(
    config => $config,
    first_name => 'xavi',
    last_name  => 'exemple',
    email      => 'xavi@somewhere.org',
    username   => 'xavi',
    realm      => 'mojito',
    password   => 'top_secret',
);
$mojito_auth->clear_db_name;
$mojito_auth->db_name('mojito_test');
my $id = $mojito_auth->add_user;

my $user = $mojito_auth->get_user('xavi');
my $name = $user->{first_name}. ' '.$user->{last_name};
my $email = $user->{email};
is($email, 'xavi@somewhere.org', 'email');
is($name, 'xavi exemple', 'name');

done_testing();