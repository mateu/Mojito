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
use MongoDB::OID;
use JSON;

use Data::Dumper::Concise;

{

	package Mojito;

	my $tmpl   = Template->new;
	my $editer = PageCRUD->new;
	my $render = PageRender->new;

	sub dispatch_request
	{

		sub (GET + /hola/* ) {
			my ($self, $name) = @_;
			[ 200, [ 'Content-type', 'text/plain' ], ["Hola $name"] ];
		  },

		  # Form to create a new page
		  sub (GET + /page ) {
			my ($self) = @_;
			[ 200, [ 'Content-type', 'text/html' ], [ $tmpl->template ] ];
		  },
		  
		  # Handle submission of a new page
		  sub (POST + /page + %* ) {
			my ($self, $params) = @_;

			my $parser       = PageParse->new(page => $params->{content});
			my $page_struct  = $parser->page_structure;
			my $id           = $editer->create($page_struct);
			my $redirect_url = "/page/${id}/edit";

			[ 301, [ Location => $redirect_url ], [] ];
		  },

          # View a page
		  sub (GET + /page/* ) {
			my ($self, $id) = @_;
			my $page = $editer->read($id);
			my $rendered_page = $render->render_page($page);
			[ 200, [ 'Content-type', 'text/html' ], [ $rendered_page ] ];
		  },
		  
		  sub (GET + /recent ) {
			my ($self) = @_;
            my $links = $editer->get_most_recent_links();
			[ 200, [ 'Content-type', 'text/html' ], [ $links ] ];
		  },

		  sub (POST + /preview + %*) {
			my ($self, $params) = @_;

			#warn "posted content: ", $params->{content};
			my $parser           = PageParse->new(page => $params->{content});
			my $page_struct      = $parser->page_structure;
			my $render           = PageRender->new;
			my $rendered_content = $render->render_page($page_struct);
			my $response_href    = { rendered_content => $rendered_content };
			my $JSON_response    = JSON::encode_json($response_href);
			[ 200, [ 'Content-type', 'application/json' ], [$JSON_response] ];
		  },

		  sub (GET + /page/*/edit ) {
			my ($self, $id, $other) = @_;
			warn "GETing page $id to edit";
			my $page             = $editer->read($id);
			my $rendered_content = $render->render_body($page);
			my $source           = $page->{page_source};

			# write source and rendered content into their tags
			my $output = $tmpl->template;

			#            my $output = $tmpl->replace_edit_page($source,$rendered_content);
			$output =~
			  s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${source}<\/textarea>/si;
			$output =~
			  s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${rendered_content}<\/section>/si;

			[ 200, [ 'Content-type', 'text/html' ], [$output] ];
		  },

		  sub (POST + /page/*/edit + %*) {
			my ($self, $id, $params) = @_;
			warn "Saving page $id to DB";
			my $parser           = PageParse->new(page => $params->{content});
			my $page             = $parser->page_structure;
			my $source           = $page->{page_source};
			my $rendered_content = $render->render_body($page);

			# Save page
			$editer->update($id, $page);
			my $output = $tmpl->template;
			$output =~
			  s/(<textarea\s+id="content"[^>]*>)<\/textarea>/$1${source}<\/textarea>/si;
			$output =~
			  s/(<section\s+id="view_area"[^>]*>)<\/section>/$1${rendered_content}<\/section>/si;

			[ 200, [ 'Content-type', 'text/html' ], [$output] ];
		  },

		  sub (GET + /bench ) {
			my ($self) = @_;
			my $parser = PageParse->new(page => $Fixture::implicit_section);
			my $page_struct = $parser->page_structure;
			my $editer      = PageCRUD->new;
			my $id     = MongoDB::OID->new(value => '4d4a3e6769f174de44000000');
			my $page   = $editer->read($id);
			my $render = PageRender->new;
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

}

Mojito->run_if_script;
