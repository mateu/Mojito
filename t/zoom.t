use lib '../lib';
use Fixture;
use Mojito::Page::Parse;
use Mojito::Page::CRUD;
use Mojito::Page::Render;
use Mojito::Template;
use MongoDB::OID;
use JSON;
use HTML::Zoom;

my $editer           = Mojito::Page::CRUD->new;
my $id               = MongoDB::OID->new( value => '4d4a3e6769f174de44000000' );
my $page             = $editer->read($id);
my $render           = Mojito::Page::Render->new;
my $rendered_content = $render->render_body($page);
warn '*** rendered content: ', $rendered_content;
my $output =
  HTML::Zoom->from_html(Template::edit_form)->select('#view_area')
  ->replace_content(\$rendered_content)->to_html;

warn '*** output: ', $output;
