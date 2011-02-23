use strictures 1;
package Mojito;
use Moo;
use Mojito::Page;

=head1 Methods

=head2 create_page

Create a new page and return its id (as a string, not an object).

=cut

sub create_page {
    my ( $self, $params ) = @_;

    my $pager = Mojito::Page->new( page => $params->{content} );
    my $page_struct = $pager->page_structure;
    $page_struct->{page_html} = $pager->render_page($page_struct);
    $page_struct->{body_html} = $pager->render_body($page_struct);
    $page_struct->{title}     = $pager->intro_text( $page_struct->{body_html} );
    my $id = $pager->create($page_struct);

    return $id;
}

sub preview_page {
    my ( $self, $params ) = @_;

    my $pager = Mojito::Page->new( page => $params->{content} );
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
# May still put in a save button later, but I think it should be tested without.   Just a 'Done' button take you to view.
        $pager->update( $params->{'mongo_id'}, $page_struct );
    }

    my $rendered_content = $pager->render_body($page_struct);
    my $response_href = { rendered_content => $rendered_content };

    return $response_href;
}

sub update_page {
    my ( $self, $params ) = @_;
    
    my $pager = Mojito::Page->new( page => $params->{content} );
    my $page = $pager->page_structure;

    # Store rendered parts as well.  May as well until proven wrong.
    $page->{page_html} = $pager->render_page($page);
    $page->{body_html} = $pager->render_body($page);
    $page->{title}     = $pager->intro_text( $page->{body_html} );

    # Save page
    $pager->update( $params->{id}, $page );
    
    return $page;
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
