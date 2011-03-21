use strictures 1;
package Mojito::Page::Render;
use 5.010;
use Moo;
use Mojito::Template;
use Mojito::Filter::Shortcuts;
use Text::Textile qw(textile);
use Text::Markdown;
use Text::WikiCreole;
use Pod::Simple::XHTML;
use HTML::Strip;
use Data::Dumper::Concise;

my $textile  = Text::Textile->new;
my $markdown = Text::Markdown->new;
my $tmpl     = Mojito::Template->new;

has base_url => ( is => 'rw', );

has 'stripper' => (
    is => 'ro',

    # isa  => 'HTML::Strip';
    lazy    => 1,
    builder => '_build_stripper',
);

=head2 render_sections

Turn the sections into something viewable in a HTML browser.

=cut

sub render_sections {
    my ( $self, $doc ) = @_;

    my ( @formatted_document_sections );
    foreach my $section ( @{ $doc->{sections} } ) {
        my $from_format = $section->{class} || $doc->{default_format};
        $from_format = $doc->{default_format} if ($section->{class} eq 'Implicit');
        my $to_format = 'HTML';
        my $formatted_section = $self->format_content( $section->{content}, $from_format, $to_format );
        push @formatted_document_sections, $formatted_section;
    }

    return \@formatted_document_sections;
}

=head2 render_page

Make a page for viewing in the browser.

=cut

sub render_page {
    my ( $self, $doc ) = @_;

    # Give the tmpl object a base url first before asking for the html template.
    my $base_url = $self->base_url;
    $tmpl->base_url($base_url);
    my $page = $tmpl->template;

    if (my $title = $doc->{title}) {
       $page =~ s/<title>.*?<\/title>/<title>${title}<\/title>/si;
    }

    my $rendered_body = $self->render_body($doc);
    # Remove edit area
    $page =~ s/(<section id="edit_area"[^>]*>).*?(<\/section>)//si;
    # Insert rendered page into view area
    $page =~ s/(<section id="view_area"[^>]*>).*?(<\/section>)/$1${rendered_body}$2/si;

    if ( my $id = $doc->{'_id'} ) {
        $page =~ s/(<nav id="edit_link"[^>]*>).*?(<\/nav>)/$1<a href="${base_url}page\/${id}\/edit">Edit<\/a>$2/sig;
    }

    return $page;
}

=head2 render_body

Turn the raw into something distilled.
TODO: Do we really need to return two things when only one is used?

=cut

sub render_body {
    my ( $self, $doc ) = @_;

    my $rendered_sections = $self->render_sections($doc);
    my $rendered_body = join "\n", @{$rendered_sections};

    $rendered_body = Mojito::Filter::Shortcuts::expand_shortcuts($rendered_body);
    return $rendered_body;
}

=head2 format_content

Given some $content, a source and target format then get the coversion started.

NOTE: We return both the non modified content, and the converted content.

=cut

sub format_content {
    my ( $self, $content, $from_format, $to_format ) = @_;
    if ( !$content ) { die "Error: no content going to format: $to_format"; }
    my $formatted_content;
    if ( $to_format eq 'HTML' ) {
        $formatted_content = $self->format_for_web( $content, $from_format );
    }

    return $formatted_content;
}

=head2 format_for_web

Given some content and its format, let's convert it to HTML.

NOTE: We return both the non modified content, and the converted content.

=cut

sub format_for_web {
    my ( $self, $content, $from_language ) = @_;

# TODO: we have language highlighters and wiki languages.
# The highlighters are to be handled by javascript.
# We could provide a shortcut syntax such: <sx c=h> to represent <pre class="prettyprint">
    my $formatted_content = $content;
    given ($from_language) {
        when (/^HTML$/i) {
            # pass HTML through as is
        }
        when (/^h$/i) {

            # Let's do some highlighting
            $formatted_content = "<pre class='prettyprint'>${content}</pre>";
        }
        when (/^POD$/i) {
            $formatted_content = $self->pod2html($content);
        }
        when (/^textile$/i) {
            $formatted_content = $textile->process($content);
        }
        when (/^markdown$/i) {
            $formatted_content = $markdown->markdown($content);
        }
        when (/^creole/i) {
            $formatted_content = creole_parse($content);
        }
        default {
            # pass HTML through as is
        }
    }
    return $formatted_content;
}

=head2 pod2html

Turn POD into HTML

=cut

sub pod2html {
    my ( $self, $content ) = @_;

    my $converter = Pod::Simple::XHTML->new;

    # We just want the body content
    $converter->html_header('');
    $converter->html_footer('');
    $converter->output_string( \my $html );
    $converter->parse_string_document($content);

    return $html;
}

=head2 intro_text

Extract the beginning text substring.

=cut

sub intro_text {
    my ( $self, $html ) = @_;

    my $title_length_limit = 32;
    my ($title) = $html =~ m/(.*)?\n?/;
    return '' if !$title;
    $title = $self->stripper->parse($title);
    if (length($title) > $title_length_limit) {
        my @words = split /\s+/, $title;
        my @title_words;
        my $title_length = 0;
        foreach my $word (@words) {
            if ($title_length + length($word) <= $title_length_limit) {
              push @title_words, $word;
              $title_length += length($word);
            }
            else {
              last;
            }
        }
        $title = join ' ', @title_words;
    }

    return $title;
}

sub _build_stripper {
    my $self = shift;

    return HTML::Strip->new();
}

1;
