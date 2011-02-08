package Template;
use strictures 1;

sub edit_form () {
    my $edit_form = <<'END_HTML';
<!doctype html> 
<html> 
<head> 
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">  
  <title>Mojito page</title> 
  <style> 
  </style>
    <script type="text/javascript" src="http://10.0.0.2/mojito/jquery/jquery-1.5.min.js"></script> 
<!--     <script type="text/javascript" src="http://10.0.0.2/mojito/jquery/jquery.form.js"></script> -->
    <script type="text/javascript" src="http://10.0.0.2/mojito/javascript/render_page.js"></script>
    <script type="text/javascript" src="http://10.0.0.2/mojito/syntax_highlight/prettify.js"></script>
    <link href="http://10.0.0.2/mojito/syntax_highlight/prettify.css" type="text/css" rel="stylesheet" />
</head>
<body>  
<section id="edit_area" style="float:left;">
<form id="editForm" action="http://localhost:5000/page" accept-charset="UTF-8" method="post"> 
    <textarea name="content" id="content" cols="72" rows="24" /></textarea><br />
    <input type="submit" id="submit" value="Submit content" /> 
</form>
</section>
<section id="preview_area" style="float:left; margin-left:1em;"></section>
</body>
</html>
END_HTML

    return $edit_form;
}



1