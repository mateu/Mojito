use strictures 1;
package Mojito::Filter::MojoMojo::Converter;
use Moo;
use 5.010;

has content => (
    is       => 'rw',
    required => 1,
);
has original_content => ( is => 'ro', );

=head1 Methods

=head2 convert_content

Run through the list of MojoMojo converters.
Currently it's just the <pre lang="$lang"> to <pre class="prettyprint">

=cut

sub convert_content {
    my ($self) = (shift);

    $self->$_ for qw/ pre_lang /;
    return $self->content;
}

=head2 pre_lang

Turn MojoMojo <pre lang="$foo">bar</pre> into:
    <pre class="prettyprint">bar</pre>

=cut

sub pre_lang {
    my ($self) = @_;

    my $content = $self->content;
    $content =~
      s/<pre\s+lang=[^>]*>(.*?)<\/pre>/<pre class="prettyprint">$1<\/pre>/sig;
    $self->content($content);
}

=head2 BUILD

Store original content

=cut

sub BUILD {
    my ($self) = (shift);
    $self->original_content( $self->content );
}

1
