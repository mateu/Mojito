use strictures 1;
package Mojito::Page::Parse;
use 5.010;
use Moo;
use Mojito::Types;

use Data::Dumper::Concise;

# This is the page source
has 'page' => (
    is       => 'rw',
    isa      => Mojito::Types::NoRef,
#    required => 1,
);
has 'sections' => (
    is      => 'ro',
    isa     => Mojito::Types::AHRef,
    lazy    => 1,
    builder => 'build_sections',
);
has 'page_structure' => (
    is      => 'rw',
    isa     => Mojito::Types::HashRef,
    lazy    => 1,
    builder => 'build_page_structure',
);
#has 'title' => (
#    is => 'ro',
#
#    #    isa     => 'Str',
#    lazy => 1,
#    default =>
#      sub { return substr( $_[0]->stripper->parse( $_[0]->page ), 0, 24 ); },
#);
has 'default_format' => (
    is => 'rw',
    isa     => Mojito::Types::NoRef,
    lazy => 1,
    default => sub { 'HTML' },
);
has 'created' => (
    is  => 'ro',
    isa => Mojito::Types::Int,
);
has 'last_modified' => (
    is      => 'ro',
    isa     => Mojito::Types::Int,
    default => sub { time() },
);
has 'section_open_regex' => (
    is      => 'ro',
    isa     => Mojito::Types::RegexpRef,
    default => sub { qr/<sx\.[^>]+>/ },
);
has 'section_close_regex' => (
    is      => 'ro',
    isa     => Mojito::Types::RegexpRef,
    default => sub { qr(</sx>) },
);
has 'debug' => (
    is      => 'rw',
    isa     => Mojito::Types::Bool,
    default => sub { 0 },
);

=head2 has_nested_section

Test if we have nested sections.

=cut

sub has_nested_section {
    my ($self) = @_;

    my $section_open_regex  = $self->section_open_regex;

    #die "Got no page" if !$self->page;
    my @stuff_between_section_opens =
      $self->page =~ m/${section_open_regex}(.*?)${section_open_regex}/sg;

    # If when find a section ending tag in the middle of the two consecutive
    # opening section tags then we know first section has been closed and thus
    # does NOT contain a nested section.
    foreach my $tweener (@stuff_between_section_opens) {
        if ( $tweener =~ m/<\/sx>/ ) {

   # The tweener section could cause us to think we're not nested
   # due to an nested section of the general type (not the class=mc_ type)
   # In this case we need to count the number of open and closed sections
   # If they are the same then we dont' have </sec> left over to close the first
   # and thus we have a nest.
            my @opens  = $tweener =~ m/(<sx[^>]*>)/sg;
            my @closes = $tweener =~ m/(<\/sx>)/sg;
            if ( scalar @opens == scalar @closes ) {
                return 1;
            }
        }
        else {
            return 1;
        }
    }

    return 0;
}

=head2 add_implicit_sections

Add implicit sections to assist the building of the page_struct.

=cut

sub add_implicit_sections {
    my ($self) = @_;

    my $page                = $self->page;
    my $section_open_regex  = $self->section_open_regex;

    # Add implicit sections in between explicit sections (if needed)
    if ( my ($tweener) = $page =~ m/<\/sx>(?!\s*<sx\.)(.*?)<sx\./si ) {
        $page =~ s/<\/sx>(?!\s*<sx\.).*?<sx\./<\/sx>\n<sx.Implicit>$tweener<\/sx>\n<sx./sig;
    }

    # Add implicit section at the beginning (if needed)
    $page =~ s/(?<!<sx\.\w)(<sx\.\w)/<\/sx>\n$1/si;
    $page = "\n<sx.Implicit>\n${page}";

    # Add implicit section at the end (if needed)
    $page =~ s/(<\/sx>)(?!.*<\/sx>)/$1\n<sx.Implicit>/si;
    $page .= '</sx>';

    # cut empty implicits
    $page =~ s/<sx\.Implicit>\s*<\/sx>//sig;

    if ( $self->debug ) {
        say "PREMATCH: ", ${^PREMATCH};
        say "MATCH:  ${^MATCH}";
        say "POSTMATCH: ", ${^POSTMATCH};
        say "page: $page";
    }

    return $page;
}

=head2 parse_sections

Extract section class and content from the page.

=cut

sub parse_sections {
    my ( $self, $page ) = @_;

    my $sections;
    my @sections = $page =~ m/(<sx\.[^>]+>.*?<\/sx>)/sig;
    foreach my $sx (@sections) {

        # Extract class and content
        my ( $class, $content ) = $sx =~ m/<sx\.([^>]+)>(.*)?<\/sx>/si;
        push @{$sections}, { class => $class, content => $content };
    }

    return $sections;
}

=head2 build_sections

Wrap up the getting of sections process.

=cut

sub build_sections {
    my $self = shift;

# TODO: Deal with nested sections gracefully.
    if ( $self->has_nested_section ) {
#        warn "page: ", $self->page;
        die "Damn: Haz Nested Sections.  Nested sections are not supported";

# return Array[]HashRef] with error when we have a nested <sx>
#        return [
#            {
#                status => 'ERROR',
#                error_message =>
#                  'We have at least one nested section which is not supported.'
#            }
#        ];
    }
    else {
        my $page = $self->add_implicit_sections;
        return $self->parse_sections($page);
    }
}

=head2 build_page_structure

It's just an href that we'll persist as a Mongo document.

=cut

sub build_page_structure {
    my $self = shift;

    return {
        sections       => $self->sections,
#        title          => $self->title,
        default_format => $self->default_format,

        #        created        => '1234567890',
        #        last_modified  => time(),
        page_source    => $self->page,
    };
}

1
