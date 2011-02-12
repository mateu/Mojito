package PageRender;
use strictures 1;
use 5.010;
use Moo;
use Template;
use Text::Textile qw(textile);
use Text::Markdown;
use Pod::Simple::XHTML;
use Data::Dumper::Concise;
use HTML::Strip;
use Shortcuts;

my $textile  = Text::Textile->new;
my $markdown = Text::Markdown->new;
my $tmpl     = Template->new;

has 'stripper' => (
    is => 'ro',

    # isa  => 'HTML::Strip';
    lazy    => 1,
    builder => '_build_stripper',
);

sub render_sections {
    my ( $self, $doc ) = @_;

    my ( @raw_document_sections, @formatted_document_sections );
    foreach my $section ( @{ $doc->{sections} } ) {

        my $from_format = $section->{class} || $doc->{default_format};
        my $to_format = 'HTML';
        my ( $raw_section, $formatted_section ) =
          $self->format_content( $section->{content}, $from_format,
            $to_format );
        push @raw_document_sections,       $raw_section;
        push @formatted_document_sections, $formatted_section;
    }

    return ( \@raw_document_sections, \@formatted_document_sections );
}

sub render_page {
    my ( $self, $doc ) = @_;

    my $page = $tmpl->template;
    
    if (my $title = $doc->{title}) {
       $page =~ s/<title>.*?<\/title>/<title>${title}<\/title>/si;
    }
    
    my $rendered_body = $self->render_body($doc);
    $page =~ s/(<section id="edit_area"[^>]*>).*?(<\/section>)//si;
    $page =~ s/(<section id="view_area"[^>]*>).*?(<\/section>)/$1${rendered_body}$2/si;
    
    if ( my $id = $doc->{'_id'} ) {
        $page =~ s/(<nav id="edit_link"[^>]*>).*?(<\/nav>)/$1<a href="\/page\/${id}\/edit">Edit<\/a>$2/si;
    }
    
    # Pieces are: $header, $title, $rendered_body, $edit_link, $footer
    return $page;
}

sub render_page_org {
    my ( $self, $doc ) = @_;

    my $header = <<'END_HTML';
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
END_HTML

    my @page_pieces = ($header);
    
    if ($doc->{title}) {
       my $title = "<title>$doc->{title}</title></head>";
       push @page_pieces, $title;
    }
    
    my $rendered_body = $self->render_body($doc);
    push @page_pieces, $rendered_body;
    
    if ( $doc->{'_id'} ) {
        my $edit_link = '<a href="/page/' . $doc->{'_id'} . '/edit">Edit</a>';
        push @page_pieces, $edit_link;
    }
    
    my $footer = "</body>\n</html>";
    push @page_pieces, $footer;

    # Pieces are: $header, $title, $rendered_body, $edit_link, $footer
    my $rendered_page = join "\n", @page_pieces;
    
    return $rendered_page;
}

sub render_body {
    my ( $self, $doc ) = @_;

    my ( $raw_sections, $rendered_sections ) = $self->render_sections($doc);
    my $rendered_body = join "\n", @{$rendered_sections};

    $rendered_body = Shortcuts::expand_shortcuts($rendered_body);
    return $rendered_body;
}

=head2 format_content

Given some $content, a source and target format then get the coversion started.

NOTE: We return both the non modified content, and the converted content.

=cut

sub format_content {
    my ( $self, $content, $from_format, $to_format ) = @_;
    if ( !$content ) { die "no content going to format: $to_format"; }
    my $formatted_content;
    if ( $to_format eq 'HTML' ) {
        $formatted_content = $self->format_for_web( $content, $from_format );
    }

    return ( $content, $formatted_content );
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
        when (/^Implicit$/i) {

            # Use default format for the page.
            # Pretend it's just Textile for now
            # my $formatter = Formatter::HTML::Textile->format($content);
            #            $formatted_content = $formatter->fragment;
            $formatted_content = $textile->process($content);

            #$formatted_content = $markdown->markdown($content);

        }
        when (/^HTML$/i) {

            # pass HTML through as is
        }
        when (/^h$/i) {

            # Let's do some highlighting
            $formatted_content = "<pre class='prettyprint'>${content}</pre>";
        }
        when (/^POD$/i) {

            #warn "Processing POD";
            $formatted_content = $self->pod2html($content);
        }
        default {
        }
    }
    return ( $content, $formatted_content );
}

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

sub intro_text {
    my ( $self, $html ) = @_;
    my ($first_line) = $html =~ m/(.*?)\n/;
    return substr( $self->stripper->parse($first_line), 0, 24 );
}

sub _build_stripper {
    my $self = shift;
    
    return HTML::Strip->new();
}

1;
