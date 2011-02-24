use strictures 1;
package Mojito::Page;
use Moo;
use Sub::Quote qw(quote_sub);

=head1 Description

An object to delegate to the Page family of objects.

=cut

=head1 Synopsis

    use Mojito::Page;
    my $page_source = $params->{content};
    my $pager = Mojito::Page->new( page_source => $page_source);
    my $web_page = $pager->render_page;

=cut

# delegatees
use Mojito::Page::Parse;
use Mojito::Page::Render;
use Mojito::Page::CRUD;
use Mojito::Template;

# roles

has parser => (
    is      => 'ro',
    isa     => sub { die "Need a PageParse object.  Have ref($_[0]) instead." unless $_[0]->isa('Mojito::Page::Parse') },
    lazy    => 1,
    handles => [
        qw(
          page_structure
          )
    ],
    writer => '_build_parse',
);

has render => (
    is      => 'ro',
    isa     => sub { die "Need a PageRender object" unless $_[0]->isa('Mojito::Page::Render') },
    handles => [
        qw(
          render_page
          render_body
          intro_text
          )
    ],
    writer => '_build_render',
);

has editer => (
    is      => 'ro',
    isa     => sub { die "Need a PageEdit object" unless $_[0]->isa('Mojito::Page::CRUD') },
    handles => [
        qw(
            create
            read
            update
            delete
            get_most_recent_links
          )
    ],
    writer => '_build_edit',
);

has tmpl => (
    is      => 'ro',
    isa     => sub { die "Need a Template object" unless $_[0]->isa('Mojito::Template') },
    handles => [
        qw(
          template
          home_page
          fillin_create_page
          fillin_edit_page
          )
    ],
    writer => '_build_template',
);
=head1 Methods

=head2 BUILD

Create the handler objects

=cut

sub BUILD {
    my $self                  = shift;
    my $constructor_args_href = shift;

    # pass the options into the subclasses
    $self->_build_parse(Mojito::Page::Parse->new($constructor_args_href));
    $self->_build_render(Mojito::Page::Render->new($constructor_args_href));
    $self->_build_edit(Mojito::Page::CRUD->new( $constructor_args_href));
    $self->_build_template(Mojito::Template->new( $constructor_args_href));

}

1