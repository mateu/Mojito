#!/usr/bin/env perl
use Dancer;
use Dancer::Plugin::Ajax;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../../../dev/Mojito/lib";
use lib __DIR__ . "/../../../dev/Mojito/t/data";
use Fixture;
use Mojito::Page;
use Mojito::Page::CRUD;
use Template;

my $tmpl = Template->new;
my $pager = Mojito::Page->new( page => '<sx>Mojito page</sx>' );

set 'logger'      => 'console';
set 'log'         => 'debug';
set 'show_errors' => 1;
set 'access_log'  => 1;
#set 'warnings' => 1;

our $VERSION = '0.1';

get '/bench' => sub {

    my $pager = Mojito::Page->new( page => $Fixture::implicit_section );
    my $page_struct = $pager->page_structure;
    my $editer      = Mojito::Page::CRUD->new( db_name => 'bench' );
    my $id          = $editer->create($page_struct);

    #my $page             = $editer->read($id);
    my $rendered_content = $pager->render_page($page_struct);

    return $rendered_content;
};

#get '/' => sub {
#    template 'index';
#};

get '/hola/:name' => sub {
    return "Hola " . params->{name};
};

get '/page' => sub {
    warn "Create Form";

    my $base_url = request->base || '/';
    my $output = $tmpl->fillin_create_page($base_url);

    return $output;
};

post '/page' => sub {
    my $pager = Mojito::Page->new( page => params->{content} );
    my $page_struct = $pager->page_structure;
    $page_struct->{page_html} = $pager->render_page($page_struct);
    $page_struct->{body_html} = $pager->render_body($page_struct);
    $page_struct->{title}     = $pager->intro_text( $page_struct->{body_html} );
    my $id           = $pager->create($page_struct);
    my $redirect_url = "/page/${id}/edit";
    redirect $redirect_url;
};

ajax '/preview' => sub {
    my $pager = Mojito::Page->new( page => params->{content} );
    my $page_struct = $pager->page_structure;
    if (   ( params->{extra_action} eq 'save' )
        && ( params->{'mongo_id'} ) )
    {
        $page_struct->{page_html} = $pager->render_page($page_struct);
        $page_struct->{body_html} = $pager->render_body($page_struct);
        $page_struct->{title} = $pager->intro_text( $page_struct->{body_html} );
        $pager->update( params->{'mongo_id'}, $page_struct );
    }

    my $rendered_content = $pager->render_body($page_struct);
    my $response_href = { rendered_content => $rendered_content };
    to_json($response_href);
};

get '/page/:id' => sub {

    my $page          = $pager->read( params->{id} );
    my $rendered_page = $pager->render_page($page);
    my $links         = $pager->get_most_recent_links;

    # Change class on view_area when we're in view mode.
    $rendered_page =~
      s/(<section\s+id="view_area").*?>/$1 class="view_area_view_mode">/si;
    $rendered_page =~
      s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;

    return $rendered_page;
};

get '/page/:id/edit' => sub {

    my $page             = $pager->read( params->{id} );
    my $rendered_content = $pager->render_body($page);
    my $source           = $page->{page_source};

    # write source and rendered content into their tags
    my $output = $tmpl->fillin_edit_page( $source, $rendered_content, params->{id}, request->base );
};

post '/page/:id/edit' => sub {

    #warn "submit value: ", params->{submit};
    my $id    = params->{id};
    my $pager = Mojito::Page->new( page => params->{content} );
    my $page  = $pager->page_structure;

    # Store rendered parts as well.  May as well until proven wrong.
    $page->{page_html} = $pager->render_page($page);
    $page->{body_html} = $pager->render_body($page);
    $page->{title}     = $pager->intro_text( $page->{body_html} );

    # Save page
    $pager->update( $id, $page );

    # If view button was pushed let's go to view
    if ( params->{submit} eq 'View' ) {
        my $redirect_url = "/page/${id}";
        redirect $redirect_url;
    }

    my $source           = $page->{page_source};
    my $rendered_content = $pager->render_body($page);
    my $output = $tmpl->fillin_edit_page( $source, $rendered_content, $id, request->base );
};

get '/page/:id/delete' => sub {
    my $id = params->{id};
    $pager->delete($id);
    redirect request->base . 'recent';
};

get '/recent' => sub {

    my $want_delete_link = 1;
    my $links            = $pager->get_most_recent_links($want_delete_link);

};

dance;
