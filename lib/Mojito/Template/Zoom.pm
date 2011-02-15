package TemplateZoom;
use Moo;
use strictures 1;
use HTML::Zoom;

# Given a template we can zoom in on parts and manipulex 'em.
has 'template' => (
    is => 'rw',
    lazy => 1,
    builder => 'build_template',
);

has 'template_z' => (
    is => 'ro',
    lazy => 1,
    builder => 'build_zoom',
);
has 'edit_area_z' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->zoom->select('#content') },
);
has 'view_area_z' => (
    is => 'ro',
    lazy => 1,
    default => sub { $_[0]->zoom->select('#view_area') },
);


sub build_zoom {
    my ($self) = @_;
    
    HTML::Zoom->new->from_html($self->template);
}

sub replace_view_area {
    my ($self, $new_content) = @_;
    
    $self->view_area->replace_content(\$new_content);
}
sub replace_edit_area{
    my ($self, $new_content) = @_;
    
    $self->edit_area->replace_content(\$new_content);
}
sub replace_edit_page {
    my ($self, $edit, $view) = @_;
    
    $self->template_z
      ->select('#content')
      ->replace_content(\$edit)
      ->select('#view_area')
      ->replace_content(\$view)->to_html;
}

sub build_template {
    my $self = shift;
     
    my $edit_page = <<'END_HTML';
<!doctype html>
<html> 
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>Mojito page</title> 
</head>
<body>  
<section id="edit_area" style="float:left;">
<form id="editForm" action="" accept-charset="UTF-8" method="post"> 
    <textarea id="content" cols="72" rows="24" /></textarea><br />
    <input id="submit" type="submit" value="Submit content" /> 
</form>
</section>
<section id="view_area" style="float:left; margin-left:1em;"></section>
</body>
</html>
END_HTML

    return $edit_page;

}
1;