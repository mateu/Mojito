package Template;
use HTML::Zoom;
use strictures 1;

use Data::Dumper::Concise;

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

 my $edit_page = <<'END_HTML';
<!doctype html>
<html> 
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Mojito page</title> 
</head>
<body>  
<section id="edit_area" style="float:left;">
</section>
<section id="view_area" style="float:left; margin-left:1em;">
</section>
</body>
</html>
END_HTML

my $edit_form = <<'END_HTML';
<form id="editForm" action="http://localhost:5000/page" accept-charset="UTF-8" method="post"> 
    <textarea name="content" id="content" cols="72" rows="24" /></textarea><br />
    <input type="submit" id="submit" value="Submit content" /> 
</form>
END_HTML

sub edit_page () {
 return HTML::Zoom
   ->from_html($edit_page)
   ->select('head')
   ->append_content([{ type => 'TEXT', raw => "${js_css}\n" }, ])
   ->select('#edit_area')
   ->replace_content(\$edit_form)
  ->to_html;
}




1
