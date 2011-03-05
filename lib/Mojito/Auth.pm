package Mojito::Auth;
use Mojito::Page;

sub authen_cb {
    my ( $username, $password ) = @_;
    
    my $mojito = Mojito::Page->new;
    $mojito->editer->collection_name('users');
    my $user = $mojito->editer->collection->find_one( { username => $username } );
    
    return $password eq $user->{password};
}

1