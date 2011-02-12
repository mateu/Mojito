use strictures 1;
package Template;
use Moo;

use Data::Dumper::Concise;

# TODO: Make this alias where Mojito/files ends up.
my $base_URL = 'http://10.0.0.2/mojito/';

has 'template' => (
    is => 'rw',
    lazy => 1,
    builder => 'build_template',
);

my $javascripts = [
    'jquery/jquery-1.5.min.js', 'javascript/render_page.js',
    'syntax_highlight/prettify.js', 'jquery/autoresize.jquery.min.js',
];
my @javascripts = map { "<script src=${base_URL}$_></script>" } @{$javascripts};

my $css = [ 'syntax_highlight/prettify.css', ];
my @css =
  map { "<link href=${base_URL}$_ type=text/css rel=stylesheet />" } @{$css};
  
my $js_css = join "\n", @javascripts, @css;

sub build_template {
    my $self = shift;
     
    my $edit_page = <<"END_HTML";
<!doctype html>
<html> 
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Mojito page</title>
$js_css
<script></script>
</head>
<body>
<table width="85%" style="margin:auto;">
<tr>
<td width="50%> 
<section id="edit_area" style="float:left;">
<form id="editForm" action="" accept-charset="UTF-8" method="post">
    <input id="mongo_id" name="mongo_id" type="hidden" form="editForm" value="" />
    <textarea id="content" name="content" cols="60"/></textarea><br />
    <input id="submit_save" name="submit" type="submit" value="Save" /> 
    <input id="submit_view" name="submit" type="submit" value="View" /> 
</form>
</section>
</td><td width="50%" valign="top"> 
<section id="view_area" style="float:left; margin-left:1em;"></section>
</td>
<td valign="top">
<section id="recent_area"></section>
</td>
</tr>
</table>
<nav id="edit_link" style="clear:both;"></nav>
</body>
</html>
END_HTML

    return $edit_page;
}


1
