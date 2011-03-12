package Mojito::Template::Role::Javascript;
use Moo::Role;
use Mojito::Types;
use Data::Dumper::Concise;

with('Mojito::Role::Config');

has javascripts => (
	is => 'ro',
	isa => Mojito::Types::ArrayRef,
	lazy => 1,
	builder => '_build_javascripts',
);

sub _build_javascripts {
	[
	  'jquery/jquery_min.js',     
	  'javascript/render_page.js',
	  'syntax_highlight/prettify.js', 
	  'jquery/autoresize_min.js',
	];
}

has javascript_html => (
	is => 'ro',
	isa => Mojito::Types::ArrayRef,	
	lazy => 1,
	builder => '_build_javascript_html',
);

sub _build_javascript_html {
	my $self = shift;
	my $static_url = $self->config->{static_url};
	my @javascripts = map { "<script src=${static_url}$_></script>" } @{$self->javascripts};
	[@javascripts];
}

1