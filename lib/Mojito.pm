use strictures 1;
package Mojito;
use Moo;

use Data::Dumper::Concise;

extends 'Mojito::Page';

=head1 Attributes

=head2 base_url

Base of the application used for creating internal links.

=cut

has base_url => ( is => 'rw', );

has bench_fixture => ( is => 'ro', lazy => 1, builder => '_build_bench_fixture');

=head1 Methods

=head2 create_page

Create a new page and return the url to redirect to, namely the page in edit mode.
We might change this to view mode if demand persuades. 

=cut

sub create_page {
    my ( $self, $params ) = @_;

    # We need to get some content into the delegatee
    $self->parser->page($params->{content});
    
    my $page_struct = $self->page_structure;
    $page_struct->{page_html} = $self->render_page($page_struct);
    $page_struct->{body_html} = $self->render_body($page_struct);
    $page_struct->{title}     = $self->intro_text( $page_struct->{body_html} );
    my $id = $self->create($page_struct);
    
    return $self->base_url . 'page/' . $id . '/edit';
}

=head2 preview_page

AJAX preview of a page (parse and render, save when button pressed)

=cut

sub preview_page {
    my ( $self, $params ) = @_;

    $self->parser->page($params->{content});
    my $page_struct = $self->page_structure;
    if (   $params->{extra_action}
        && ( $params->{extra_action} eq 'save' )
        && ( $params->{'mongo_id'} ) )
    {
        $page_struct->{page_html} = $self->render_page($page_struct);
        $page_struct->{body_html} = $self->render_body($page_struct);
        $page_struct->{title} = $self->intro_text( $page_struct->{body_html} );
        $self->update( $params->{'mongo_id'}, $page_struct );
    }
    elsif ( $params->{'mongo_id'} ) {

# Auto update this stuff so the user doesn't have to even think about clicking save button
# TODO: add title, page and body html to page_struct like above.
#       Do we even need these two branches given that we're autosaving now.
# TODO: on new page, insert to get an id then update to that from the start
        $self->update( $params->{'mongo_id'}, $page_struct );
    }

    my $rendered_content = $self->render_body($page_struct);
    my $response_href = { rendered_content => $rendered_content };

    return $response_href;
}

=head2 update_page

Update a page given: content, id and base_url

=cut

sub update_page {
    my ( $self, $params ) = @_;

    $self->parser->page($params->{content});
    my $page = $self->page_structure;

    # Store rendered parts as well.  May as well until proven wrong.
    $page->{page_html} = $self->render_page($page);
    $page->{body_html} = $self->render_body($page);
    $page->{title}     = $self->intro_text( $page->{body_html} );
    
    # Add a feed if there is such a param
    if (my $feeds = $params->{feeds}) {
        # Allow : to separate multiple feeds. e.g. ?feed=ironman:chatterbox
        my @feeds = split ':', $feeds;
        $page->{feeds} = [@feeds]; 
    }

    # Save page
    $self->update( $params->{id}, $page );

    return $self->base_url . 'page/' . $params->{id};
}

=head2 edit_page_form

Present the form with a page ready to be edited.

=cut

sub edit_page_form {
    my ( $self, $params ) = @_;

    my $page             = $self->read( $params->{id} );
    my $rendered_content = $self->render_body($page);
    my $source           = $page->{page_source};

    return $self->fillin_edit_page( $source, $rendered_content, $params->{id} );
}

=head2 view_page

Given a page id, we retrieve its page from the db and return
the HTML form of the page to the browser.

=cut

sub view_page {
    my ( $self, $params ) = @_;

    my $page          = $self->read( $params->{id} );
    my $rendered_page = $self->render_page($page);
    my $links         = $self->get_most_recent_links;

    # Change class on view_area when we're in view mode.
    $rendered_page =~
      s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
    $rendered_page =~
      s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

    return $rendered_page;
}

=head2 view_page_public

Given a page id, we retrieve its page from the db and return
the HTML form of the page to the browser.  This method is much
like the view_page() method is setup for public pages
(ones that do not require authentication).

=cut

sub view_page_public {
    my ( $self, $params ) = @_;

    my $page          = $self->read( $params->{id} );
    my $rendered_page = $self->render_page($page);

    # Change class on view_area when we're in view mode.
    $rendered_page =~
      s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
    
    # Strip out Edit and New links (even though they are Auth::Digest Protected)
    # Remove edit, new links and the recent area
    $rendered_page =~ s/<nav id="edit_link".*?><\/nav>//sig;
    $rendered_page =~ s/<nav id="new_link".*?>.*?<\/nav>//sig;
    $rendered_page =~ s/<section id="recent_area".*?><\/section>//si;
    
    return $rendered_page;
}

=head2 view_home_page

Create the view for the base of the application.

=cut

sub view_home_page {
    my $self = shift;

    my $output = $self->home_page;
    my $links  = $self->get_most_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    
    return $output;
}

=head2 delete_page

Delet a page given a page id.
Return the URL to recent (maybe home someday?)

=cut

sub delete_page {
    my ( $self, $params ) = @_;
    $self->delete($params->{id});
    return $self->base_url . 'recent';
}

=head2 bench

A path for benchmarking to get an basic idea of peformance.

=cut

sub bench {
    my $self  = shift;
    
    $self->parser->page($self->bench_fixture);
    my $page_struct = $self->page_structure;
    
    # Let's run our bench stuff in its own DB to keep it separate from
    # real (user created) pages.
    $self->editer->db_name('bench');
    my $id = $self->create($page_struct);
    
    return $self->render_page($page_struct);
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
