use strictures 1;

package Mojito::Model::MetaCPAN;
use Moo;
use HTTP::Tiny;
use MetaCPAN::API;
use Text::MultiMarkdown;
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
    is      => 'ro',
    lazy    => 1,
    default => sub { MetaCPAN::API->new },
);

has cache => (
    is      => 'rw',
    default => sub {
        CHI->new(
            driver => 'Memory',
            global => 1,
#            driver   => 'File',
#            root_dir => '/tmp/chi_cache',
        );
    },
);

has not_found_string => (
    is => 'rw',
    lazy => 1,
   'default' => sub { 'NOT FOUND' },
);

has markdown => (
    is => 'ro',
    lazy => 1,
    'default' => sub { return Text::MultiMarkdown->new }
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

    return if not $synopsis;
    return wantarray ? split "\n", $synopsis : $synopsis;
}

sub get_synopsis_from_metacpan {
    my ($self, $Module) = @_;

    my $pod_url =
      "http://api.metacpan.org/pod/${Module}?content-type=text/x-markdown";
    my $response = $self->http_client->get($pod_url);
    if (not $response->{success}) {
        return $self->not_found_string;
    }
    my $content        = $response->{content}; # if length $response->{content};
    my @synopsis_lines = ();
    my $seen_synopsis = my $seen_synopsis_end = 0;
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

sub get_description_from_metacpan {
    my ($self, $Module) = @_;
    
    my $pod_url =
      "http://api.metacpan.org/pod/${Module}?content-type=text/x-markdown";
    my $response = $self->http_client->get($pod_url);
    if (not $response->{success}) {
        #warn "Failed to get URL: $pod_url";
        return;
    }
    my $content = $response->{content}; # if length $response->{content};
    my @description_lines = ();
    my $seen_description = my $seen_description_end = 0;
    my @content_lines = split '\n', $content;

    foreach (@content_lines) {
        
        # Are we starting the section after the Synopsis?
        if ($seen_description && m/^#\s/) {
            $seen_description_end = 1;
        }
        if (m/^#\s+DESCRIPTION/i) {
            $seen_description = 1;
        }
        if ($seen_description && not $seen_description_end) {
            push @description_lines, $_;
        }
    }
    return wantarray ? @description_lines : join "\n", @description_lines;
}
    
=head2 get_synopsis_formatted

    signature: (a Perl Module name, an element of qw/presentation/)
    example: my $synop = $self->get_synopsis_formatted('Moose', 'presentation');
    
=cut

sub get_synopsis_formatted {
    my ($self, $Module, $format) = @_;
    $format ||= 'presentation';

    # Just have the presentation format for starters.
    my $dispatch_table = {
        presentation => sub {

            my @synopsis_lines = $self->get_synopsis_from_metacpan($Module);
            @synopsis_lines = $self->trim_lines(@synopsis_lines);
            if (not scalar @synopsis_lines) {
                return $self->not_found_string;
            }
            
            # Comment out lines that don't start with a comment
            # and are not indented (i.e. not code)
            # because we'd like the Synopsis to be runnable (in theory)
            my ($whitespace) = $synopsis_lines[0] =~ m/^(\s*)/;
            @synopsis_lines = map { my $line = $_; $line =~ s/^(\w)/&#35; $1/; $line; } @synopsis_lines;

            # Trim off leading whitespace (usually 2 or 4)
            @synopsis_lines = map { my $line = $_; $line =~ s/^$whitespace//; $line; } @synopsis_lines;
            my $synopsis = join "\n", @synopsis_lines;

            # pre wrapper for syntax highlight
            $synopsis = "<pre class='prettyprint'>\n" . $synopsis . "</pre>\n";

            $synopsis = "<h2 class='Module'><a href='http://metacpan.org/module/${Module}'>${Module}</a></h2>". $synopsis;
            return $synopsis;
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

=head2 trim_lines

Remove first line
Remove leading and trailing blank lines

=cut

sub trim_lines {
    my ($self, @lines) = @_;

    return if not scalar @lines;

    # Get rid of first line and any blank line directly after
    # We'll rewrite the first line and are making the results more
    # compact by removing the blank lines.
    shift @lines;
    return if not scalar @lines;
    while ($lines[0] =~ m/^\s*?$/) {
        shift @lines;
    }
    return if not scalar @lines;

    # Do same for tail
    while ($lines[-1] =~ m/^\s*?$/) {
        pop @lines;
    }
    return if not scalar @lines;
    return @lines;
}
=head2 get_recent_releases_from_metacpan

    Get an ArrayRef[HashRef] of the most recent CPAN releases

=cut

sub get_recent_releases_from_metacpan {
    my ($self, $how_many) = @_;
    $how_many ||= 10;

    my @fields        = qw/author name distribution version maturity download_url/;
    my $fields_string = join ',', @fields;
    my $result        = $self->metacpan->release(
        search => {
            sort   => "date:desc",
            fields => $fields_string,
            size   => $how_many,
        },
    );

    return [ map { $_->{fields} } @{ $result->{hits}->{hits} } ];
}

=head2 recent_synopses_shortcut

    Create the Mojito shortcut that gets the synopses of the most 
    recently released CPAN distributions.  Looks like:
    
    {{synopsis Module1}}
    {{synopsis Module2}}
    ...
    {{synopsis Modulen}}
    
=cut

sub recent_synopses_shortcut {
    my ($self, $how_many) = @_;
    $how_many ||= 10;

    my $cache_key = "CPAN_RECENT_SYNOPSES:${how_many}";
    my $synopses  = $self->cache->get($cache_key);
    if (not $synopses) {
        warn "GET Recent Release from CPAN" if $ENV{MOJITO_DEBUG};
        my @releases = $self->get_recent_releases_from_metacpan($how_many);
        my @recent_synopses = map { "{{cpan.synopsis $_}}" } 
        map {
            my $dist = $_->{distribution}; 
            $dist =~ s/\-/::/g;
            $dist;
        } @releases;
        $synopses = join "\n", @recent_synopses;
        $self->cache->set($cache_key, $synopses, '1 minute');
    }
    return $synopses;
}

=head2 get_recent_releases

Get the most recent releases (as module names)
    
=cut

sub get_recent_releases {
    my ($self, $how_many) = @_;
    $how_many ||= 10;

    my $cache_key = "CPAN_RECENT_RELEASES:${how_many}";
    my $releases  = $self->cache->get($cache_key);
    if (not $releases) {
        warn "GET Recent Releases from CPAN" if $ENV{MOJITO_DEBUG};
        $releases = $self->get_recent_releases_from_metacpan($how_many);
        $self->cache->set($cache_key, $releases, '1 minute');
    }
    return $releases;
}

=head2 get_recent_synopses

Get the most recent synopses from CPAN
    
=cut

sub get_recent_synopses {
    my ($self, $how_many) = @_;
    $how_many ||= 10;
    my $metacpan_web_host = 'https://metacpan.org';

    my $html;
    my $releases = $self->get_recent_releases($how_many);
    # Avoid duplicatds
    my %have_seen = ();
    foreach my $release (@{$releases}) {
        my $main_module = $release->{distribution}; 
        $main_module =~ s/\-/::/g;
        next if $have_seen{$main_module};
        my $synopsis = $self->get_synopsis_formatted($main_module, 'presentation');
        my $not_found_message = '';
        if ($synopsis eq $self->not_found_string) {
            $not_found_message = 'Synopsis not found for '; 
            if ($release->{maturity} eq 'released') {
                $html .= "<section class='released'>$not_found_message 
                <a href='${metacpan_web_host}/release/$release->{author}/$release->{name}'>$release->{name}</a>
                </section>\n";
            }
            else {
                $html .= "<section class='developer'>$not_found_message
                <a href='${metacpan_web_host}/release/$release->{author}/$release->{name}'>$release->{name}</a>
                <span style='font-size: 88%;'> (dev)</span>
                </section>\n";
            }
        }
        else {
            $html .= $synopsis;
        }
        $have_seen{$main_module}++; 
    }
    return $html;
}

