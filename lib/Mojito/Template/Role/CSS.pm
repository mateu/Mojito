use strictures 1;
package Mojito::Template::Role::CSS;
use Moo::Role;
use Mojito::Types;

with('Mojito::Role::Config');

has css => (
    is => 'ro',
    isa => Mojito::Types::ArrayRef,
    lazy => 1,
    builder => '_build_css',
);

sub _build_css {
    [
      'syntax_highlight/prettify.css',
      'css/mojito.css',
    ];
}

has css_html => (
    is => 'ro',
    isa => Mojito::Types::ArrayRef,
    lazy => 1,
    builder => '_build_css_html',
);

sub _build_css_html {
    my $self = shift;
    my $static_url = $self->config->{static_url};
    my @css =  map { "<link href=${static_url}$_ type=text/css rel=stylesheet />" } @{$self->css};
    [@css];
}

1
