package RecentSynopses;
use strictures 1;
use Web::Simple;
use Mojito::Model::MetaCPAN;
use Mojito::Template;
use Mojito::Filter::MojoMojo::Converter;

with('Mojito::Role::Config');

=head1 Name

RecentSynopses - a mini-app that show recent CPAN synopses

=cut

has converter => (
    is   => 'ro',
    lazy => 1,
    default =>
      sub { Mojito::Filter::MojoMojo::Converter->new(content => 'yet to come') }
    ,
);

has metacpan => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Mojito::Model::MetaCPAN->new },
);
has tmpl => (
    is   => 'ro',
    lazy => 1,
    default =>
      sub { Mojito::Template->new(config => $_[0]->config) },
);

sub dispatch_request {
    my ($self, $env) = @_;

    sub (GET + /recent/*) {
        my ($self, $amount) = @_;

        $amount ||= 10;
        my $max = 40;
        $amount = ($amount > $max) ? $max : $amount;
        my $body = $self->metacpan->get_recent_synopses($amount);
        $body = '<h1>Recent Synopses from CPAN</h1> {{toc 2-}} ' . $body;
        $self->converter->content($body);
        $self->converter->toc;
        my $html =
          $self->tmpl->wrap_page($self->converter->content, 'Recent CPAN Synapses');
        [ 200, [ 'Content-type', 'text/html' ], [$html] ];
      },

}

sub BUILD {
    my ($self, $args) = @_;

    my $pid = fork;
    if (not $pid) {

        # code executed only by the child ...
        while (1) {
            $self->metacpan->get_recent_synopses;
            sleep 60;
        }
    }
    else {
        warn "Parent has born a child with PID: $pid!";
    }
}

RecentSynopses->run_if_script;
