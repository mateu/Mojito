use strictures 1;
package Mojito::Role::Config;
use Moo::Role;
use Mojito::Types;
use Cwd qw/ abs_path /;
use Dir::Self;

has 'config' => (
    is  => 'ro',
    isa => Mojito::Types::HashRef,
    lazy => 1,
    builder => '_build_config',
);

=head2 get_config

Read the configuration file.  (technique pilfered from Mojo::Server::Hypntoad).
Config file is looked for in three locations:
    ENV
    lib/Mojito/conf/mojito_local.conf
    lib/Mojito/conf/mojito.conf
The first location that exists is used.

=cut

sub _build_config {

    my $file =
         $ENV{MOJITO_CONFIG}
      || abs_path(__DIR__ . '/../conf/mojito_local.conf')
      || abs_path(__DIR__ . '/../conf/mojito.conf');


    # Config
    my $config = {};
    if ( -r $file ) {
        unless ( $config = do $file ) {
            die qq/Can't load config file "$file": $@/ if $@;
            die qq/Can't load config file "$file": $!/ unless defined $config;
            die qq/Config file "$file" did not return a hashref.\n/
              unless ref $config eq 'HASH';
        }
    }

    # Let's add in the version number.
    $config->{VERSION} = $Mojito::Role::Config::VERSION || 'development version';
    return $config;
}

1