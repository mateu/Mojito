#!/usr/bin/env perl

use Web::Simple 'Mojito';
use Dir::Self;
use lib __DIR__ . "/../lib";
use lib __DIR__ . "/../t/data";
use Fixture;
use PageParse;
use PageCRUD;
use PageRender;
use Template;
use JSON;

{

	package Mojito;

	my $tmpl   = Template->new;
	my $editer = PageCRUD->new;
	my $render = PageRender->new;
	use Data::Dumper::Concise;
	use FindBin qw/$Bin/;

	sub dispatch_request
	{

		sub (GET + /deploy/*) {
			my ($self, $deploy_location) = @_;

			warn "Deploying to location: $deploy_location";
			my $env = $_[PSGI_ENV];

			[ 200, [ 'Content-type', 'text/plain' ], ["Raison d'etre"] ];
		  },

		  sub (GET + /hola/* ) {
			my ($self, $name) = @_;
			[ 200, [ 'Content-type', 'text/plain' ], ["Hola $name"] ];
		  },

		  # Form to create a new page
		  sub (GET + /page ) {
			my ($self) = @_;
			
		    my $output = $tmpl->template;
		    my ${base_url} = $_[PSGI_ENV]->{SCRIPT_NAME}||'/';
            $output =~ s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview'<\/script>/s;
            
			[ 200, [ 'Content-type', 'text/html' ], [ $output ] ];
		  },

		  # Handle submission of a new page
		  sub (POST + /page + %* ) {
			my ($self, $params) = @_;

			warn "content: ", $params->{content};
			my $parser = PageParse->new(page => $params->{content});

			warn "submit type: ", $params->{submit};
			my $page_struct  = $parser->page_structure;
			my $id           = $editer->create($page_struct);
			my $redirect_url = "/page/${id}/edit";

			[ 301, [ Location => $redirect_url ], [] ];
		  },

		  # View a page
		  sub (GET + /page/* ) {
			my ($self, $id) = @_;
			my $page          = $editer->read($id);
			my $rendered_page = $render->render_page($page);
			[ 200, [ 'Content-type', 'text/html' ], [$rendered_page] ];
		  },

		  # List pages in chrono order
		  sub (GET + /recent ) {
			my ($self) = @_;
			my $links = $editer->get_most_recent_links();
			[ 200, [ 'Content-type', 'text/html' ], [$links] ];
		  },

		  # Handler for previews (and will save if save button is pushed).
		  sub (POST + /preview + %*) {
			my ($self, $params) = @_;

			#warn "posted content: ", $params->{content};
			warn "extra action: ", $params->{extra_action};
			my $parser = PageParse->new(page => $params->{content});
			my $page_struct = $parser->page_structure;
			if (   ($params->{extra_action} eq 'save')
				&& ($params->{'mongo_id'}))
			{
				$editer->update($params->{'mongo_id'}, $page_struct);
			}

			my $render           = PageRender->new;
			my $rendered_content = $render->render_body($page_struct);
			my $response_href    = { rendered_content => $rendered_content };
			my $JSON_response    = JSON::encode_json($response_href);
			[ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
		  },

		  # Load a page to edit
		  sub (GET + /page/*/edit ) {
			my ($self, $id, $other) = @_;
			warn "GETing page $id to edit";
			my $page             = $editer->read($id);
			my $rendered_content = $render->render_body($page);
			my $source           = $page->{page_source};

			# write source and rendered content into their tags
			my $output = fillin_edit_page($source, $rendered_content, $id, base_url($_[PSGI_ENV]));

			[ 200, [ 'Content-type', 'text/html' ], [$output] ];
		  },

		  # Update a page
		  sub (POST + /page/*/edit + %*) {
			my ($self, $id, $params) = @_;
			warn "Saving page $id to DB";
			warn "submit value: ", $params->{submit};
			my $parser = PageParse->new(page => $params->{content});
			my $page = $parser->page_structure;

			# Save page
			$editer->update($id, $page);

			# If view button was pushed let's go to view
			if ($params->{submit} eq 'View')
			{
				warn "going to View for id: $id";
				my $redirect_url = "/page/${id}";

				return [ 301, [ Location => $redirect_url ], [] ];
			}

			my $source           = $page->{page_source};
			my $rendered_content = $render->render_body($page);
			my $output = fillin_edit_page($source, $rendered_content, $id, base_url($_[PSGI_ENV]));

			return [ 200, [ 'Content-type', 'text/html' ], [$output] ];
		  },

		  # Delete a page
		  sub (GET + /page/*/delete ) {
			my ($self, $id, $other) = @_;
			$editer->delete($id);
			return [ 301, [ Location => '/recent' ], [] ];
		  },

		  # A Benchmark URI
		  sub (GET + /bench ) {
			my ($self) = @_;
			my $parser = PageParse->new(page => $Fixture::implicit_section);
			my $page_struct      = $parser->page_structure;
			my $editer           = PageCRUD->new;
			my $id               = '4d4a3e6769f174de44000000';
			my $page             = $editer->read($id);
			my $render           = PageRender->new;
			my $rendered_content = $render->render_page($page_struct);
			[ 200, [ 'Content-type', 'text/html' ], [$rendered_content] ];
		  },

		  sub (GET) {
			[ 200, [ 'Content-type', 'text/plain' ], ['Hello world!'] ];
		  },

		  sub () {
			[ 405, [ 'Content-type', 'text/plain' ], ['Method not allowed'] ];
		  }
	}

	sub fillin_edit_page
	{
		my ($page_source, $page_view, $mongo_id, $base_url) = @_;

		my $output = $tmpl->template;
		$output =~ s/<script><\/script>/<script>mojito.preview_url = '${base_url}preview'<\/script>/s;
		$output =~ s/(<input id="mongo_id".*?value=)""/$1"${mongo_id}"/si;
		$output =~
		  s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${page_source}<\/textarea>/si;
		$output =~
		  s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${page_view}<\/section>/si;

		return $output;
	}
	
	sub base_url {
	    my $env = shift;

        my $uri = $env->{SCRIPT_NAME} || '/';
#          ($env->{'psgi.url_scheme'} || "http") 
#          . "://"
#          . (
#            $env->{HTTP_HOST}
#              || (($env->{SERVER_NAME} || "") 
#              . " : "
#              . ($env->{SERVER_PORT} || 80))
#          ) . ($env->{SCRIPT_NAME} || '/');
        return $uri;
	}

}

Mojito->run_if_script;
