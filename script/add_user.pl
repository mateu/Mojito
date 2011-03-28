use strictures 1;
use Term::Prompt;
use Mojito::Auth;
use 5.010;

my $realm = 'Mojito';
my ( $first_name, $last_name, $email, $username, $password_1, $password_2 );
PROMPT:
{

    #realm = prompt( 'x', 'realm:',    '', 'Mojito' );
    $first_name = prompt( 'x', 'first name:',       '', '' );
    $last_name  = prompt( 'x', 'last name:',        '', '' );
    $email      = prompt( 'x', 'email:',            '', '' );
    $username   = prompt( 'x', 'username:',         '', '' );
    $password_1 = prompt( 'p', 'password:',         '', '' );
    $password_2 = prompt( 'p', "confirm password:", '', '' );

    if ( $password_1 ne $password_2 ) {
        say "Passwords don't match!";
        goto PROMPT;
    }
}
my $mojito_auth = Mojito::Auth->new(
    first_name => $first_name,
    last_name  => $last_name,
    email      => $email,
    username   => $username,
    realm      => $realm,
    password   => $password_1
);

my $id = $mojito_auth->add_user;

say 'Added user: ', $mojito_auth->username, " with id: $id";

