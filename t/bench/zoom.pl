use Benchmark qw(:all);
use FindBin qw($Bin);
use lib "$Bin/../data";
use 5.010;

#use Template;
use HTML::Zoom;
my $html_frag = '<section id=view_area></section>';
my $zoom      = HTML::Zoom->new;
my $zoom_view = $zoom->from_html($html_frag)->select('#view_area');

my $count = 10000;

my $result = cmpthese(
    $count,
    {
        'replace' => sub {
            $zoom_view->replace_content('Whoa')->to_html;
        },
        'divide'  => sub { 1.3 / 2.7 },
        'conquer' => sub {
            sub {
                sub { my $goodness = rand }
              }
        },
    }
);
