package PageRender;
#use strictures 1;
use 5.010;
use Moo;
use Formatter::HTML::Textile;
use Text::Textile qw(textile);
#use Text::MultiMarkdown 'markdown';
use Text::Markdown;

use Pod::Simple::XHTML;

my $textile = new Text::Textile;
my $markdown = Text::Markdown->new;

#use Data::Dumper::Concise;
sub render_sections {
    my ( $self, $doc ) = @_;

    #say "Getting sections for document with title: ", $doc->{title};
    my ( @raw_document_sections, @formatted_document_sections );
    foreach my $section ( @{ $doc->{sections} } ) {

        #say "Section title: ", $section->{title};
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

    my $rendered_body =  $self->render_body($doc);

    my $header = <<'END_HTML';
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
END_HTML

    my $title  = "<title>$doc->{title}</title></head>";
    my $footer = '</body></html>';

    my $rendered_page = join "\n", $header, $title, $rendered_body, $footer;
    return $rendered_page;
}

sub render_body {
    my ( $self, $doc ) = @_;

    my $rendered_sections = $self->render_sections($doc);
    my $rendered_body = join "\n", @{$rendered_sections};

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

1;
