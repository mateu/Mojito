use strictures 1;
package Mojito;
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
    * Prematurely optimized ;)
    * HTML5

=head1 Current Limitations

    * No Auth support
    * No Search
    * Hardwired to a 'documents' named mongo db and a 'notes' collection
    * No revision history


=head1 Authors

Mateu Hunter C<hunter@missoula.org>

=head1 Copyright

Copyright 2011, Mateu Hunter

=head1 License

You may distribute this code under the same terms as Perl itself.

=cut
