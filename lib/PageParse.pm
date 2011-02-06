package PageParse;

#use strictures 1;
use 5.010;
use Moo;
use Types;

#use HTML::HTML5::Parser;
use Sub::Quote qw/ quote_sub /;
use HTML::Strip;

use Data::Dumper::Concise;

has 'page' => (
    is       => 'rw',
    isa      => Types::NoRef,
    required => 1,
);
has 'sections' => (
    is      => 'ro',
    isa     => Types::AHRef,
    builder => 'build_sections',
);
has 'page_structure' => (
    is      => 'rw',
    isa     => Types::HashRef,
    lazy    => 1,
    builder => 'build_page_structure',
);
has 'title' => (
    is => 'ro',

    #    isa     => 'Str',
    lazy => 1,
    default =>
      sub { return substr( $_[0]->stripper->parse( $_[0]->page ), 0, 16 ); },
);
has 'default_format' => (
    is => 'ro',

    #    isa     => 'Str',
    default => sub { 'HTML' },
);
has 'created' => (
    is  => 'ro',
    isa => Types::Int,
);
has 'last_modified' => (
    is      => 'ro',
    isa     => Types::Int,
    default => sub { time() },
);
has 'section_open_regex' => (
    is      => 'ro',
    isa     => Types::RegexpRef,
    default => sub { qr/<sx c=(?:'|")?\w+(?:'|")?/ },
);
has 'section_close_regex' => (
    is      => 'ro',
    isa     => Types::RegexpRef,
    default => sub { qr(</sx>) },
);
has 'debug' => (
    is      => 'rw',
    isa     => Types::Bool,
    default => sub { 0 },
);
has 'stripper' => (
    is   => 'ro',
    # isa  => 'HTML::Strip';
    lazy => 1,
    builder => '_build_stripper',
);

sub has_nested_section {
    my ($self) = @_;

    my $section_open_regex  = $self->section_open_regex;
    my $section_close_regex = $self->section_close_regex;

    my @stuff_between_section_opens =
      $self->page =~ m/${section_open_regex}(.*?)${section_open_regex}/sg;

    # If when find a section ending tag in the middle of the two consecutive
    # opening section tags then we know first section has been closed and thus
    # does NOT contain a nested section.
    my $has_nested_section = 0;
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

sub add_implicit_sections {
    my ($self) = @_;

    my $page                = $self->page;
    my $section_open_regex  = $self->section_open_regex;
    my $section_close_regex = $self->section_close_regex;

    # look behinds need a fixed distance.  Let's provide them one by collapsing
    # whitespace in just the right spot, betweeen <sx and c=
    $page =~ s/(<sx\s+c=)/<sx c=/sgi;

    # Add implicit sections in between explicit sections (if needed)
    $page =~
s/(<\/sx>)(.*?\S.*?)($section_open_regex)/$1\n<sx c=Implicit>$2<\/sx>\n$3/sig;

    # Add implicit section at the beginning (if needed)
    $page =~ s/(?<!<sx c=)(<sx c=)/<\/sx>\n$1/si;
    $page = "\n<sx c=Implicit>\n${page}";

    # Add implicit section at the end (if needed)
    $page =~ s/(<\/sx>)(?!.*<\/sx>)/$1\n<sx c=Implicit>/si;
    $page .= '</sx>';

    # cut empty implicits
    $page =~ s/<sx c=Implicit>\s*<\/sx>//sig;

    if ( $self->debug ) {
        say "PREMATCH: ", ${^PREMATCH};
        say "MATCH:  ${^MATCH}";
        say "POSTMATCH: ", ${^POSTMATCH};
        say "page: $page";
    }

    return $page;
}

=head2 parse_sections

Parse the HTML5ish creation after we've added implicit sections
	
	Args: sectioned HTMLish stuff (after adding implicit sections to raw/source content)
	Returns: Data structure of sections - ArrayRef[HashRef]
	         [{content => $some, class => 'Implicit'}]
	         
=cut

sub parse_html5 {
    my ( $self, $html5 ) = @_;

    #    my $parser         = HTML::HTML5::Parser->new;
    #    my $doc            = $parser->parse_string($html5);
    #    my $tagname        = 'sx';
    #    my $attribute_name = 'c';
    #    my $nodelist       = $doc->getElementsByTagName('sx');
    #    my $sections;
    #    while ( my $node = $nodelist->shift ) {
    #        my $section;
    #        if ( $node->getAttribute($attribute_name) ) {
    #            $section->{class} = $node->getAttribute('c');
    #        }
    #        else {
    #            $section->{class} = 'Implicit';
    #        }
    #        my $content = $node->toString;
    #
    #        # Remove inclosing tags
    #        $content =~ s/<sx c=[^>]>(.*)<\sx>/$1/si;
    #
    #        # Store it
    #        $section->{content} = $content;
    #        push @{$sections}, $section;
    #    }
    #
    #    return $sections;
    return [ {} ];
}

sub parse_sections {
    my ( $self, $page ) = @_;

    my $sections;
    my @sections = $page =~ m/(<sx c=[^>]+>.*?<\/sx>)/sig;
    foreach my $sx (@sections) {

        # Extract class and content
        my ( $class, $content ) =
          $sx =~ m/<sx c=(?:'|")?(\w+)?(?:'|")?>(.*)?<\/sx>/si;
        push @{$sections}, { class => $class, content => $content };
    }

    return $sections;
}

=head2 build_sections

Wrap up the getting of sections process.

=cut

sub build_sections {
    my $self = shift;

    if ( $self->has_nested_section ) {

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

sub build_page_structure {
    my $self = shift;

    return {
        sections       => $self->sections,
        title          => $self->title,
        default_format => $self->default_format,

        #        created        => '1234567890',
        #        last_modified  => time(),
    };
}

sub _build_stripper {
    my $self = shift;
    
    return HTML::Strip->new();
}

1
