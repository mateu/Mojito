use strictures 1;

package Mojito::Model::MetaCPAN;
use Moo;
use HTTP::Tiny;
use MetaCPAN::API;
use CHI;
use Data::Dumper::Concise;

=head1 Name

Mojito::Model::MetaCPAN - Tap into metacpan.org

=cut

has http_client => (
    is      => 'ro',
    lazy    => 1,
    default => sub { HTTP::Tiny->new },
);

has metacpan => (
    is => 'ro',
    lazy => 1,
    default => sub { MetaCPAN::API->new },
);

has cache => (
    is      => 'rw',
    default => sub {
        CHI->new(
            driver   => 'Memory',
            global   => 1
        );
    },
);

=head1 Methods

=head2 get_synopsis

Retrieve the pod for a given module (in markdown format). 
Extract the SYNOPSIS and return it.

=cut

sub get_synopsis {
    my ($self, $Module) = @_;
    return if not $Module;

    my $cache_key = "${Module}:SYNOPSIS";
    my $synopsis  = $self->cache->get($cache_key);
    if (not $synopsis) {
        warn "GET $Module from CPAN" if $ENV{MOJITO_DEBUG};
        $synopsis = $self->get_synopsis_from_metacpan($Module);
        $self->cache->set($cache_key, $synopsis, '1 day');
    }

    return wantarray ? split "\n", $synopsis : $synopsis;
}

sub get_synopsis_from_metacpan {
    my ($self, $Module) = @_;

    my $pod_url =
      "http://api.metacpan.org/pod/${Module}?content-type=text/x-markdown";
    my $response = $self->http_client->get($pod_url);
    if (not $response->{success}) {
        warn "Failed to get URL: $pod_url";
        return;
    }
    my $content        = $response->{content}; # if length $response->{content};
    my @synopsis_lines = ();
    my $seen_synopsis  = 0;
    my $seen_synopsis_end = 0;
    my @content_lines = split '\n', $content;

    foreach (@content_lines) {

        # Are we starting the section after the Synopsis?
        if ($seen_synopsis && m/^#\s/) {
            $seen_synopsis_end = 1;
        }
        if (m/^#\s+SYNOPSIS/i) {
            $seen_synopsis = 1;
        }
        if ($seen_synopsis && not $seen_synopsis_end) {
            push @synopsis_lines, $_;
        }
    }
    return wantarray ? @synopsis_lines : join "\n", @synopsis_lines;
}

=head2 get_synopsis_formatted

    signature: (a Perl Module name, an element of qw/presentation/)
    example: my $synop = $self->get_synopsis_formatted('Moose', 'presentation');
    
=cut

sub get_synopsis_formatted {
    my ($self, $Module, $format) = @_;

    my $no_synopsis_message =
      "<div style='font-size: 1.33em;'>SYNOPSIS Not Found for 
    <strong><a href='http://metacpan.org/module/${Module}'>${Module}</a></strong></div>";

    # Just have the presentation format for starters.
    my $dispatch_table = {
        presentation => sub {

            my @synopsis_lines = $self->get_synopsis_from_metacpan($Module);
            return $no_synopsis_message if not scalar @synopsis_lines;

            # Get rid of first line and any blank line directly after
            # We'll rewrite the first line and are making the results more
            # compact by removing the blank lines.
            shift @synopsis_lines;
            return $no_synopsis_message if not scalar @synopsis_lines;
            while ($synopsis_lines[0] =~ m/^\s*?$/) {
                shift @synopsis_lines;
            }
            return $no_synopsis_message if not scalar @synopsis_lines;

            # Do same for tail
            while ($synopsis_lines[-1] =~ m/^\s*?$/) {
                pop @synopsis_lines;
            }
            return $no_synopsis_message if not scalar @synopsis_lines;

            # Comment out lines that don't start with a comment
            # and are not indented (i.e. not code) 
            # because we'd like the Synopsis to be runnable (in theory)
            my ($whitespace) = $synopsis_lines[0] =~ m/^(\s*)/;
            @synopsis_lines = map { s/^(\w)/# $1/; $_; } @synopsis_lines;

            # Trim off leading whitespace (usually 2 or 4)
            @synopsis_lines = map { s/^$whitespace//; $_; } @synopsis_lines;

            # pre wrapper for syntax highlight
            unshift @synopsis_lines, '<pre class="sh_perl">';
            push @synopsis_lines, '</pre>';

            # section title
            unshift @synopsis_lines,
"<h2 class='Module'><a href='http://metacpan.org/module/${Module}'>${Module}</a></h2>";

            return join "\n", @synopsis_lines;
          }
    };
    my $cache_key = "${Module}:SYNOPSIS:${format}";
    my $synopsis  = $self->cache->get($cache_key);
    if (not $synopsis) {
        warn "GET $Module SYNOPSIS from CPAN" if $ENV{MOJITO_DEBUG};
        $synopsis = $dispatch_table->{$format}->($Module);
        $self->cache->set($cache_key, $synopsis, '1 day');
    }
    return $synopsis;
}

=head2 get_recent_releases_from_metacpan

    Get a Hash of the most recent CPAN releases
    where they keys are: Module Names
     and the values are: Module Versions

=cut
   

sub get_recent_releases_from_metacpan {
    my ($self, $how_many) = @_;
    $how_many ||= 10;
    
    my $result = $self->metacpan->release(
        search => {
            sort   => "date:desc",
            fields => "name",
            size   => $how_many,
        },
    );
    my @recent_releases =
      map { $_->{fields}->{name} } @{ $result->{hits}->{hits} };
    my %recent_releases = map { s/\-([^\-]*)$//; $_ => $1; } @recent_releases;
    %recent_releases =
      map { my $org = $_; s/\-/\:\:/g; $_ => $recent_releases{$org}; }
      keys %recent_releases;
    return %recent_releases;
}

=head2 get_recent_synopses

    Get the synopses of the most recently released distribution to CPAN.
    
=cut

sub get_recent_synopses {
    my ($self, $how_many) = @_;
    $how_many ||= 10;
        
    my $cache_key = "CPAN_RECENT_SYNOPSES:${how_many}";
    my $synopses  = $self->cache->get($cache_key);
    if (not $synopses) {
        warn "GET Recent Release from CPAN" if $ENV{MOJITO_DEBUG};
        my %releases = $self->get_recent_releases_from_metacpan($how_many);
        my @recent_synopses = map { "{{synopsis ${_}}}" } keys %releases;
        $synopses = join "\n", @recent_synopses;
        $self->cache->set($cache_key, $synopses, '30 seconds');
    }
    return $synopses;
}