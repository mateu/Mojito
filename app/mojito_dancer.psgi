#!/usr/bin/env perl
use Dancer;
use Dancer::Plugin::Ajax;
use Mojito;

use Data::Dumper::Concise;

my ($mojito, $base_url);
set 'logger'      => 'file';
setting log_path => '/tmp';
set 'log_path'    => '/tmp';
setting log_dir => '/tmp';
set 'log_dir'    => '/tmp';
set 'appdir'     => '/tmp';
#set 'log'         => 'debug';
#set 'show_errors' => 1;
#set 'access_log'  => 1;
#set 'warnings' => 1;

before sub {
    $base_url = request->base;
    if ($base_url !~ m/\/$/) {
        $base_url .= '/';
    }
    $mojito = Mojito->new( base_url => $base_url);
    var base_url => $base_url;
};

get '/bench' => sub {
    return $mojito->bench;
};

get '/hola/:name' => sub {
    return "Hola " . params->{name};
};

get '/page' => sub {
    return $mojito->fillin_create_page;
};

post '/page' => sub {
    redirect $mojito->create_page(scalar params);
};

ajax '/preview' => sub {
    to_json( $mojito->preview_page(scalar params) );
};

get '/page/:id' => sub {
    return $mojito->view_page( {id => params->{id}} );
};

get '/page/:id/edit' => sub {
    return $mojito->edit_page_form( {id => params->{id}} );
};

post '/page/:id/edit' => sub {
    redirect $mojito->update_page(scalar params);
};

get '/page/:id/delete' => sub {
    my $id = params->{id};
    redirect $mojito->delete_page( {id => params->{id}} );
};

get '/recent' => sub {
    my $want_delete_link = 1;
    my $links            = $mojito->get_most_recent_links($want_delete_link);
    return $links;
};

get '/' => sub {
    my $output = $mojito->home_page;
    my $links  = $mojito->get_most_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    return $output;
};

dance;
