use strictures 1;
package Mojito::Template;
use Moo;
use Data::Dumper::Concise;

# TODO - MOST DO: Make this alias where Mojito/files ends up.
my $base_URL = 'http://localhost/mojito/';

has 'template' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_template',
);
has 'home_page' => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_home_page',
);

my $javascripts = [
    'jquery/jquery-1.5.min.js',     'javascript/render_page.js',
    'syntax_highlight/prettify.js', 'jquery/autoresize.jquery.min.js',
];
my @javascripts = map { "<script src=${base_URL}$_></script>" } @{$javascripts};

my $css = [ 'syntax_highlight/prettify.css', 'css/mojito.css', ];
my @css =
  map { "<link href=${base_URL}$_ type=text/css rel=stylesheet />" } @{$css};

my $js_css = join "\n", @javascripts, @css;

sub _build_template {
    my $self = shift;

    my $edit_page = <<"END_HTML";
<!doctype html>
<html> 
<head>
  <meta charset=utf-8>
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class="html_body">
<header>
<nav id="edit_link" class="edit_link"></nav>
<nav id="new_link" class="new_link"> <a href=/page>New</a></nav>
</header>
<article id="body_wrapper">
<section id="edit_area">
<form id="editForm" action="" accept-charset="UTF-8" method="post">
    <input id="mongo_id" name="mongo_id" type="hidden" form="editForm" value="" />
    <textarea id="content"  name="content" rows=24 /></textarea><br />
    <input id="submit_save" name="submit" type="submit" value="Save" /> 
    <input id="submit_view" name="submit" type="submit" value="Done" /> 
</form>
</section>
<section id="view_area" class="view_area_edit_mode"></section>
<section id="recent_area"></section>
</article>
<footer>
<nav id="edit_link" class="edit_link"></nav>
<nav id="new_link" class="new_link"> <a href=/page>New</a></nav>
</footer>
</body>
</html>
END_HTML

    return $edit_page;
}

sub _build_home_page {
    my $self = shift;

    my $home_page = <<"END_HTML";
<!doctype html>
<html> 
<head>
  <meta charset=utf-8>
  <title>Mojito page</title>
$js_css
<script></script>
<style></style>
</head>
<body class=html_body>
<header>
<nav id="new_link" class="new_link"> <a href=/page>New</a></nav>
</header>
<article id="body_wrapper">
<section id="recent_area"></section>
</article>
<footer>
<nav id="new_link" class="new_link"> <a href=/page>New</a></nav>
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
    my ( $self, $page_source, $page_view, $mongo_id, $base_url ) = @_;

    my $output = $self->template;
    $output =~ s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview';<\/script>/s;
    $output =~ s/(<input id="mongo_id".*?value=)""/$1"${mongo_id}"/si;
    $output =~ s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${page_source}<\/textarea>/si;
    $output =~ s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${page_view}<\/section>/si;

    # An Experiment in Design: take out the save button, because we have autosave every few seconds
    # plus the "View" button will be renamed "Done"
     $output =~ s/<input id="submit_save".*?>//sig;
    
    # Remove recent area
    $output =~ s/<section id="recent_area".*?><\/section>//si;

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
    my ( $self, $base_url ) = @_;

    my $output = $self->template;
   
    # Set mojito preiview_url variable
    $output =~ s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview'<\/script>/;

    # Take out view button and change save to create.
    $output =~ s/<input id="submit_view".*?>//;
    $output =~ s/<input id="submit_save"(.*?>)/<input id="submit_create"$1/;
    $output =~ s/(id="submit_create".*?value=)"Save"/$1"Create"/i;

    # Remove recent area
    $output =~ s/<section id="recent_area".*?><\/section>//si;

    # Remove edit and new links
    $output =~ s/<nav id="edit_link".*?><\/nav>//sig;
    $output =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;

    # body with no style
    $output =~ s/<body.*?>/<body>/si;
    
    return $output;
}


1