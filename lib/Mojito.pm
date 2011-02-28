use strictures 1;
package Mojito;
use Moo;
use Mojito::Page;
use Mojito::Page::CRUD;

use Data::Dumper::Concise;

=head1 Attributes

=head2 base_url

Base of the application used for creating internal links.

=cut

has base_url => ( is => 'rw', );

has bench_fixture => ( is => 'ro', lazy => 1, builder => '_build_bench_fixture');

=head1 Methods

=head2 create_page

Create a new page and return its id (as a string, not an object).

=cut

sub create_page {
    my ( $self, $params ) = @_;

    my $pager = Mojito::Page->new(
        page     => $params->{content},
        base_url => $self->base_url
    );
    my $page_struct = $pager->page_structure;
    $page_struct->{page_html} = $pager->render_page($page_struct);
    $page_struct->{body_html} = $pager->render_body($page_struct);
    $page_struct->{title}     = $pager->intro_text( $page_struct->{body_html} );
    my $id = $pager->create($page_struct);

    return $id;
}

=head2 preview_page

AJAX preview of a page (parse and render, save when button pressed)

=cut

sub preview_page {
    my ( $self, $params ) = @_;

    my $pager = Mojito::Page->new(
        page     => $params->{content},
        base_url => $self->base_url
    );
    my $page_struct = $pager->page_structure;
    if (   $params->{extra_action}
        && ( $params->{extra_action} eq 'save' )
        && ( $params->{'mongo_id'} ) )
    {
        $page_struct->{page_html} = $pager->render_page($page_struct);
        $page_struct->{body_html} = $pager->render_body($page_struct);
        $page_struct->{title} = $pager->intro_text( $page_struct->{body_html} );
        $pager->update( $params->{'mongo_id'}, $page_struct );
    }
    elsif ( $params->{'mongo_id'} ) {

# Auto update this stuff so the user doesn't have to even think about clicking save button
# May still put in a save button later, but I think it should be tested without.
# Just a 'Done' button take you to view.
# TODO: add title, page and body html to page_struct like above.
#       Do we even need these two branches given that we're autosaving now.
# TODO: on new page, insert to get an id then update to that from the start
        $pager->update( $params->{'mongo_id'}, $page_struct );
    }

    my $rendered_content = $pager->render_body($page_struct);
    my $response_href = { rendered_content => $rendered_content };

    return $response_href;
}

=head2 update_page

Update a page given: content, id and base_url

=cut

sub update_page {
    my ( $self, $params ) = @_;

    my $pager = Mojito::Page->new(
        page     => $params->{content},
        base_url => $self->base_url
    );
    my $page = $pager->page_structure;

    # Store rendered parts as well.  May as well until proven wrong.
    $page->{page_html} = $pager->render_page($page);
    $page->{body_html} = $pager->render_body($page);
    $page->{title}     = $pager->intro_text( $page->{body_html} );

    # Save page
    $pager->update( $params->{id}, $page );

    return $page;
}

=head2 edit_page_form

Present the form with a page ready to be edited.

=cut

sub edit_page_form {
    my ( $self, $params ) = @_;

    my $pager = Mojito::Page->new(
        page     => '<b>Mojito page</b>',
        base_url => $self->base_url
    );
    my $page             = $pager->read( $params->{id} );
    my $rendered_content = $pager->render_body($page);
    my $source           = $page->{page_source};

    return $pager->fillin_edit_page( $source, $rendered_content,
        $params->{id} );
}

=head2 view_page

Given a page id, we retrieve its page from the db and return
the HTML form of the page to the browser.

=cut

sub view_page {
    my ( $self, $params ) = @_;

    warn Dumper $params;
# page is required for PageParser so let's put in a placeholder to make it happen
# when it gets delegated to during BUILD of page delegator object
    my $pager = Mojito::Page->new(
        page     => '<b>Mojito page</b>',
        base_url => $self->base_url
    );
    my $page          = $pager->read( $params->{id} );
    my $rendered_page = $pager->render_page($page);
    my $links         = $pager->get_most_recent_links( 0, $self->base_url );

    # Change class on view_area when we're in view mode.
    $rendered_page =~
      s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
    $rendered_page =~
      s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

    return $rendered_page;
}

=head2 bench

A path for benchmarking to get an basic idea of peformance.

=cut

sub bench {
    my $self  = shift;
    my $pager = Mojito::Page->new(
        page     => $self->bench_fixture,
        base_url => $self->base_url,
    );
    my $page_struct = $pager->page_structure;
    my $editer      = Mojito::Page::CRUD->new( db_name => 'bench' );
    my $id          = $editer->create($page_struct);
    
    return $pager->render_page($page_struct);
}

sub _build_bench_fixture {
    my $self = shift;
    
    my $implicit_section = <<'END';
h1. Greetings

<sx c=Perl>
use Modern::Perl;
say 'something';
</sx>

Implicit Section

<sx c="JavaScript">
function () { var one = 1 }
</sx>

Stuff After

END
    return $implicit_section;
}

1;
__END__

=head1 Name

Mojito - A Lightweight Web Document System

=cut

=head1 Description

Mojito is a web document system that allows one to author web pages.  
It has been inspired by MojoMojo which is a mature, stable, responsive and 
feature rich wiki system.  Check MojoMojo out if you're looking for an enterprise
grade wiki.  Mojito is not attempting to be a wiki, but rather its initial 
goal is to allow an individuals to author HTML5 compliant documents that could be for 
personal or public consumption.

=head1 Goals

Mojito is in alpha stage so it has much growing to do.  
Some goals and guidelines are:

    * Somewhat Framework Agnostic.  Currently there is support for 
      Web::Simple, Dancer and Mojo with Tatsumaki support planned)
    * Minimalistic Interface.  No Phluff or at least options to turn features off.
    * A page engine that can standalone or potentially be plugged into MojoMojo.  
    * Exchange between MojoMojo and Mojito document formats.
    * HTML5

=head1 Current Limitations

    * No Auth support
    * No Search
    * Hardwired to a 'documents' named mongo db and a 'notes' collection
    * No revision history (only 1 version any any page)
    * Prematurely optimized ;)


=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2011, Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut
