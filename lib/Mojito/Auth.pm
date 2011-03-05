use strictures 1;
package Mojito::Auth;
use Mojito::Page;

=head1 Methods

=head2 authen_cb

The authentication callback used by Plack::Middleware::Authen::Basic.

=cut

sub authen_cb {
    my ( $username, $password ) = @_;
    
    my $mojito = Mojito::Page->new;
    $mojito->editer->collection_name('users');
    my $user = $mojito->editer->collection->find_one( { username => $username } );
    
    return $password eq $user->{password};
}

1