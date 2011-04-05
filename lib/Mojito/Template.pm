use strictures 1;
package Mojito::Template;
use Moo;
use Mojito::Types;
use Mojito::Model::Link;
use Data::Dumper::Concise;

with('Mojito::Template::Role::Javascript');
with('Mojito::Template::Role::CSS');

has 'template' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_template',
);

has base_url => ( is => 'rw', );

has 'home_page' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_home_page',
);

has 'collect_page_form' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_collect_page_form',
);

has 'collections_index' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_collections_index',
);

has js_css_html => (
    is => 'ro',
    isa => Mojito::Types::NoRef,
    default => sub { my $self = shift; join "\n", @{$self->javascript_html}, @{$self->css_html} }
);

has page_wrap_start => (
    is => 'ro',
    lazy => 1,
    builder => '_build_page_wrap_start',
);

has page_wrap_end => (
    is => 'ro',
    lazy => 1,
    builder => '_build_page_wrap_end',
);

sub _build_template {
    my $self = shift;

    my $base_url  = $self->base_url;
    my $mojito_version = $self->config->{VERSION};
    my $js_css = $self->js_css_html;
    my $edit_page = <<"END_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta http-equiv="powered by" content="Mojito $mojito_version" />
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class="html_body">
<header>
<nav id="edit_link" class="edit_link"></nav>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</header>
<section id="message_area"></section>
<article id="body_wrapper">
<section id="edit_area">
<form id="editForm" action="" accept-charset="UTF-8" method="post">
    <div id="wiki_language">
        <input type="radio" id="textile"  name="wiki_language" value="textile" checked="checked" /><label for="textile">textile</label>
        <input type="radio" id="markdown" name="wiki_language" value="markdown" /><label for="markdown">markdown</label>
        <input type="radio" id="creole"   name="wiki_language" value="creole" /><label for="creole">creole</label>
        <input type="radio" id="html"     name="wiki_language" value="html" /><label for="html">html</label>
    </div>
    <input id="mongo_id" name="mongo_id" type="hidden" form="editForm" value="" />
    <input id="wiki_language" name="wiki_language" type="hidden" form="editForm" value="" />
    <textarea id="content"  name="content" rows=32 required="required"/></textarea>
    <input id="commit_message" name="commit_message" value="commit message" onclick="this.value == 'commit message' ? this.value = '' : true"/>
    <input id="submit_save" name="submit" type="submit" value="Save" style="font-size: 66.7%;" />
    <input id="submit_view" name="submit" type="submit" value="Done" style="font-size: 66.7%;" />
</form>
</section>
<section id="view_area" class="view_area_edit_mode"></section>
<nav id="side">
<section id="search_area">
<form action=${base_url}search method=POST>
<input type="text" name="word" value="Search" onclick="this.value == 'Search' ? this.value = '' : true"/>
</form>
</section><br />
<section id="collections_area"></section>
<section id="recent_area"></section>
</nav>
</article>
<footer>
<nav id="edit_link" class="edit_link"></nav>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</footer>
</body>
</html>
END_HTML

    return $edit_page;
}


sub _build_page_wrap_start {
    my $self = shift;

    my $mojito_version = $self->config->{VERSION};
    my $js_css = $self->js_css_html;
    my $page_start = <<"START_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta http-equiv="powered by" content="Mojito $mojito_version" />
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class="html_body">
<section id="message_area"></section>
<article id="body_wrapper">
START_HTML

    return $page_start;
}
sub _build_page_wrap_end {
    my $self = shift;

    my $page_end =<<'END_HTML';

</article>
</body>
</html>
END_HTML

    return $page_end;
}

=head2 wrap_page

Wrap a page body with start and end HTML.

=cut

sub wrap_page {
    my ($self, $page_body) = @_;
    return $self->page_wrap_start . $page_body . $self->page_wrap_end;
}

sub _build_collect_page_form {
    my $self = shift;
    my $list = Mojito::Model::Link->new(base_url => $self->base_url);
    return $self->wrap_page($list->view_selectable_page_list);
}

sub _build_collections_index {
    my $self = shift;
    my $list = Mojito::Model::Link->new(base_url => $self->base_url);
    return $self->wrap_page($list->view_collections_index);
}

=head2 sort_collection_form

A form to sort a collection of pages.

=cut

sub sort_collection_form {
    my ($self, $collection_id) = (shift, shift);
    my $list = Mojito::Model::Link->new(base_url => $self->base_url);
    return $self->wrap_page($list->view_sortable_page_list({ collection_id => $collection_id }));
}

=head2 collection_page

Given a collection id, show a list of belonging pages.

=cut

sub collection_page {
    my ($self, $collection_id) = (shift, shift);
    my $list = Mojito::Model::Link->new(base_url => $self->base_url);
    return $self->wrap_page($list->view_collection_page({ collection_id => $collection_id }));
}

sub _build_home_page {
    my $self = shift;

    my $base_url  = $self->base_url;
    my $mojito_version = $self->config->{VERSION};
    my $js_css = $self->js_css_html;
    my $home_page = <<"END_HTML";
<!doctype html>
<html>
<head>
  <meta charset=utf-8>
  <meta http-equiv="powered by" content="Mojito $mojito_version" />
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class=html_body>
<header>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</header>
<article id="body_wrapper">
<nav id="side">
<section id="search_area"><form action=${base_url}search method=POST><input type="text" name="word" value="Search" onclick="this.value == 'Search' ? this.value = '' : true" /></form></section><br />
<section id="recent_area"></section>
</nav>
</article>
<footer>
<nav id="new_link" class="new_link"> <a href=${base_url}page>New</a></nav>
</footer>
</body>
</html>
END_HTML

    return $home_page;
}

=head1 Methods

=head2 fillin_edit_page

Get the contents of the edit page proper given the starting template and some data.

=cut

sub fillin_edit_page {
    my ( $self, $page_source, $page_view, $mongo_id, $wiki_language ) = @_;

    my $output   = $self->template;
    my $base_url = $self->base_url;
    $output =~
s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview';<\/script>/s;
    $output =~ s/(<input id="mongo_id".*?value=)""/$1"${mongo_id}"/si;
    $output =~ s/(<input id="wiki_language".*?value=)""/$1"${wiki_language}"/si;
    $output =~
s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${page_source}<\/textarea>/si;
    $output =~
s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${page_view}<\/section>/si;

# An Experiment in Design: take out the save button, because we have autosave every few seconds
    $output =~ s/<input id="submit_save".*?>//sig;

    # Remove side, recent area and wiki_language (for create only)
    $output =~ s/<nav id="side">.*?<\/nav>//si;
#    $output =~ s/<section id="recent_area".*?><\/section>//si;
    $output =~ s/<div id="wiki_language".*?>.*?<\/div>//si;

    # Remove edit and new links
    $output =~ s/<nav id="edit_link".*?><\/nav>//sig;
    $output =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;

    # body with no style
    $output =~ s/<body.*?>/<body>/si;

    return $output;
}

=head2 fillin_create_page

Get the contents of the create page proper given the starting template and some data.

=cut

sub fillin_create_page {
    my ($self) = @_;

    my $output   = $self->template;
    my $base_url = $self->base_url;

    # Set mojito preiview_url variable
    $output =~
s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview'<\/script>/;

    # Take out view button and change save to create.
    $output =~ s/<input id="submit_view".*?>//;
    $output =~ s/<input id="submit_save"(.*?>)/<input id="submit_create"$1/;
    $output =~ s/(id="submit_create".*?value=)"Save"/$1"Create"/i;

    # Remove side nav area
    $output =~ s/<nav id="side">.*?<\/nav>//si;

    # Remove wiki_language hidden input (for edit)
    $output =~ s/<input id="wiki_language".*?\/>//sig;

    # Remove edit and new links
    $output =~ s/<nav id="edit_link".*?><\/nav>//sig;
    $output =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;

    # body with no style
    $output =~ s/<body.*?>/<body>/si;

    return $output;
}

1
