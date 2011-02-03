package PageRender;
use strictures;
use 5.010;
use Moo;
use Formatter::HTML::Textile;
use Syntax::Highlight::Engine::Kate::All;
use Syntax::Highlight::Engine::Kate;
use Pod::Simple::XHTML;
use Data::Dumper::Concise;

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
    my ($self, $doc) = @_;
    
    my $rendered_sections = $self->render_sections($doc);
    my $rendered_body = join "\n", @{$rendered_sections};

    my $header = <<'END_HTML';
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
END_HTML

    my $title  = "<title>$doc->{title}</title>";
    my $footer = '</body></html>';

    my $rendered_page = join "\n", $header, $title, $rendered_body, $footer;
    return $rendered_page;
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
    my ( $self, $content, $from_format ) = @_;

    # TODO: Use just one highlighter (combine this one with one below).
    my $highlighter = new Syntax::Highlight::Engine::Kate;
    my %supported_languages = map { $_ => 1, } $highlighter->languageList;

    my $formatted_content = $content;
    given ($from_format) {
        when (/^Implicit$/i) {
            # Use default format for the page.
            # Pretend it's just Textile for now
            my $formatter = Formatter::HTML::Textile->format( $content );
            $formatted_content = $formatter->fragment;
            
        }
        when (/^HTML$/i) {

            # pass HTML through as is
        }
        when (/^POD$/i) {

            #warn "Processing POD";
            $formatted_content = $self->pod2html($content);
        }
        default {
            if ( $supported_languages{$from_format} ) {

                $formatted_content =
                  $self->syntax_highlighter( $content, $from_format );
            }
            elsif ( $from_format eq 'PHP' ) {
                $self->syntax_highlighter( $content, 'PHP (HTML)' );
            }
            else {
                die "I don't have a formatter for $from_format";
            }
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

sub syntax_highlighter {
    my ( $self, $content, $language ) = @_;

    my $highlighter = new Syntax::Highlight::Engine::Kate(
        language      => $language,
        substitutions => {
            "<"  => "&lt;",
            ">"  => "&gt;",
            "&"  => "&amp;",
            " "  => "&nbsp;",
            "\t" => "&nbsp;&nbsp;&nbsp;",
            "\n" => "<br />\n",
        },
        format_table => {
            Alert    => [ "<font color=\"#0000ff\">",       "</font>" ],
            BaseN    => [ "<font color=\"#007f00\">",       "</font>" ],
            BString  => [ "<font color=\"#c9a7ff\">",       "</font>" ],
            Char     => [ "<font color=\"#ff00ff\">",       "</font>" ],
            Comment  => [ "<font color=\"#7f7f7f\"><i>",    "</i></font>" ],
            DataType => [ "<font color=\"#0000ff\">",       "</font>" ],
            DecVal   => [ "<font color=\"#00007f\">",       "</font>" ],
            Error    => [ "<font color=\"#ff0000\"><b><i>", "</i></b></font>" ],
            Float    => [ "<font color=\"#00007f\">",       "</font>" ],
            Function => [ "<font color=\"#007f00\">",       "</font>" ],
            IString  => [ "<font color=\"#ff0000\">",       "" ],
            Keyword  => [ "<b>",                            "</b>" ],
            Normal   => [ "",                               "" ],
            Operator => [ "<font color=\"#ffa500\">",       "</font>" ],
            Others   => [ "<font color=\"#b03060\">",       "</font>" ],
            RegionMarker => [ "<font color=\"#96b9ff\"><i>", "</i></font>" ],
            Reserved     => [ "<font color=\"#9b30ff\"><b>", "</b></font>" ],
            String       => [ "<font color=\"#ff0000\">",    "</font>" ],
            Variable     => [ "<font color=\"#0000ff\"><b>", "</b></font>" ],
            Warning => [ "<font color=\"#0000ff\"><b><i>", "</b></i></font>" ],
        },
    );
    my %supported_languages = map { $_ => 1, } $highlighter->languageList;
    die "Language: $language not supported" if !$supported_languages{$language};

    return $highlighter->highlightText($content);
}

1;
