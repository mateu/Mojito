use strictures 1;
package Mojito::Role::Config;
use Moo::Role;
# Let dzil (Makefile.PL) know that we need at least version 0.02
use MooX::Types::MooseLike 0.02 qw(:all);
use Cwd qw/ abs_path /;
use Dir::Self;

has 'config' => (
    is  => 'ro',
    isa => HashRef,
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
NOTE: This means the configuration is not the UNION of all available config files.

=cut

sub _build_config {

    my $conf_file  = abs_path(__DIR__ . '/../conf/mojito.conf');
    my $local_conf = abs_path(__DIR__ . '/../conf/mojito_local.conf');
    # See if a local conf exists
    if (-r $local_conf) {
        $conf_file = $local_conf;
    }

    # Allow an ENV to take precedent.
    my $file = $ENV{MOJITO_CONFIG} || $conf_file;

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
