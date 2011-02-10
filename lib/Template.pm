use strictures 1;
package Template;
use Moo;

use Data::Dumper::Concise;

has 'template' => (
    is => 'rw',
    lazy => 1,
    builder => 'build_template',
);

my $base_URL = 'http://10.0.0.2/mojito/';

my $javascripts = [
    'jquery/jquery-1.5.min.js', 'javascript/render_page.js',
    'syntax_highlight/prettify.js',
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
</head>
<body>  
<section id="edit_area" style="float:left;">
<form id="editForm" action="" accept-charset="UTF-8" method="post">
    <input id="mongo_id" name="mongo_id" type="hidden" form="editForm" value="" />
    <textarea id="content" name="content" cols="72" rows="24" /></textarea><br />
    <input id="submit_save" name="submit" type="submit" value="Save" /> 
    <input id="submit_view" name="submit" type="submit" value="View" /> 
</form>
</section>
<section id="view_area" style="float:left; margin-left:1em;"></section>
</body>
</html>
END_HTML

    return $edit_page;
}


1
