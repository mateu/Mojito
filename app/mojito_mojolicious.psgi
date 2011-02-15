#!/usr/bin/env perl
use Mojolicious::Lite;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use Mojito::Page;
use Mojito::Page::Parse;
use Mojito::Page::CRUD;
use Mojito::Page::Render;
use Mojito::Template;
use Data::Dumper::Concise;

my $tmpl = Mojito::Template->new;
my $pager = Mojito::Page->new( page => '<sx>Mojito page</sx>' );

get '/bench' => sub {
    my $self        = shift;
    
    my $pager = Mojito::Page->new( page => $Fixture::implicit_section );
    my $page_struct = $pager->page_structure;
    my $editer      = Mojito::Page::CRUD->new( db_name => 'bench' );
    my $id          = $editer->create($page_struct);
    my $rendered_content = $pager->render_page($page_struct);
    
    $self->render( text => $rendered_content );
};

get '/hola/:name' => sub {
    my $self = shift;
    $self->render( text => "Hola " . $self->param('name') );
};

get '/page' => sub {
    my $self = shift;
    
    # base should have a ending '/' for properness
    # We'll add it.
    my $base_url = $self->req->url->base || '/';
    if ($base_url =~ m/[^\/]$/) {
       $base_url .= '/'; 
    }
    my $output = $tmpl->fillin_create_page($base_url);
    
    $self->render( text => $output );
};

post '/page' => sub {
    my $self = shift;
    
    my $pager = Mojito::Page->new( page => $self->param('content') );
    my $page_struct = $pager->page_structure;
    $page_struct->{page_html} = $pager->render_page($page_struct);
    $page_struct->{body_html} = $pager->render_body($page_struct);
    $page_struct->{title}     = $pager->intro_text( $page_struct->{body_html} );
    my $id           = $pager->create($page_struct);
    # TODO: use base where needed to locate app to URI in general framework case 
    my $base_url = $self->req->url->base || '/';
    my $redirect_url = $base_url . "/page/${id}/edit";
    
    $self->redirect_to($redirect_url);
};

post '/preview' => sub {
    my $self = shift;
    
    my $pager = Mojito::Page->new( page => $self->param('content') );
    my $page_struct = $pager->page_structure;
    if ( $self->param('extra_action') eq 'save' && $self->param('mongo_id') ) {
        $page_struct->{page_html} = $pager->render_page($page_struct);
        $page_struct->{body_html} = $pager->render_body($page_struct);
        $page_struct->{title} = $pager->intro_text( $page_struct->{body_html} );
        $pager->update( $self->param('mongo_id'), $page_struct );
    }

    my $rendered_content = $pager->render_body($page_struct);
    my $response_href = { rendered_content => $rendered_content };

    $self->render( json => $response_href );
};

get '/page/:id' => sub {
    my $self = shift;

    my $page          = $pager->read($self->param('id'));
    my $rendered_page = $pager->render_page($page);
    my $links         = $pager->get_most_recent_links;

    # Change class on view_area when we're in view mode.
    $rendered_page =~
      s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
    $rendered_page =~
      s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

    $self->render( text => $rendered_page );
};

get '/page/:id/edit' => sub {
    my $self = shift;

    my $page             = $pager->read($self->param('id'));
    my $rendered_content = $pager->render_body($page);
    my $source           = $page->{page_source};

    # write source and rendered content into their tags
    my $base_url = $self->req->url->base || '/';
    if ($base_url =~ m/[^\/]$/) {
       $base_url .= '/'; 
    }
    my $output = $tmpl->fillin_edit_page( $source, $rendered_content, $self->param('id'), $base_url );
    $self->render( text => $output );
};

post '/page/:id/edit' => sub {
    my $self = shift;
    
    warn "submit value: ", $self->param('submit');
    my $id    = $self->param('id');
    my $pager = Mojito::Page->new( page => $self->param('content') );
    my $page  = $pager->page_structure;

    # Store rendered parts as well.  May as well until proven wrong.
    $page->{page_html} = $pager->render_page($page);
    $page->{body_html} = $pager->render_body($page);
    $page->{title}     = $pager->intro_text( $page->{body_html} );

    # Save page
    $pager->update( $id, $page );

    # If view button was pushed let's go to view
    if ( $self->param('submit') eq 'View' ) {
        my $redirect_url = "/page/${id}";
        #redirect $redirect_url;
        $self->redirect_to($redirect_url);
    }

    my $source           = $page->{page_source};
    my $rendered_content = $pager->render_body($page);
    my $base_url = $self->req->url->base || '/';
    if ($base_url =~ m/[^\/]$/) {
       $base_url .= '/'; 
    }
    my $output = $tmpl->fillin_edit_page( $source, $rendered_content, $id, $base_url );
    $self->render( text => $output );
};

get '/page/:id/delete' => sub {
    my $self = shift;
    
    my $id = $self->param('id');
    $pager->delete($id);
    
    $self->redirect_to($self->req->url->base . '/recent');
};

get '/recent' => sub {
    my $self = shift;
    my $want_delete_link = 1;
    my $links            = $pager->get_most_recent_links($want_delete_link);
    $self->render( text => $links );
};

get '/' => sub {
    my $self = shift;
    my $output = $tmpl->home_page;
    my $links  = $pager->get_most_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    $self->render( text => $output );
};

app->start;
