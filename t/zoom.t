use lib '../lib';
use Fixture;
use PageParse;
use PageCRUD;
use PageRender;
use Template;
use MongoDB::OID;
use JSON;
use HTML::Zoom;

my $editer           = PageCRUD->new;
my $id               = MongoDB::OID->new( value => '4d4a3e6769f174de44000000' );
my $page             = $editer->read($id);
my $render           = PageRender->new;
my $rendered_content = $render->render_body($page);
warn '*** rendered content: ', $rendered_content;
my $output =
  HTML::Zoom->from_html(Template::edit_form)->select('#view_area')
  ->replace_content(\$rendered_content)->to_html;

warn '*** output: ', $output;
