#!/usr/bin/env perl
use Dancer;
use Dancer::Plugin::Ajax;
use 5.010;
use Dir::Self;
use lib __DIR__ . "/../../../dev/Mojito/lib";
use lib __DIR__ . "/../../../dev/Mojito/t/data";
use Mojito::Page;
use Mojito;

use Data::Dumper::Concise;

my $mojito = Mojito->new;
my ($pager, $base_url);
set 'logger'      => 'console';
set 'log'         => 'debug';
set 'show_errors' => 1;
set 'access_log'  => 1;

#set 'warnings' => 1;

before sub {
    $base_url = request->base;
    if ($base_url !~ m/\/$/) {
        $base_url .= '/';
    }
    $mojito->base_url($base_url);
    $pager = Mojito::Page->new( page => '<sx>Mojito page</sx>', base_url => $base_url );
    var base_url => $base_url;
    var pager => $pager;
};

get '/bench' => sub {
    return $mojito->bench;
};

get '/hola/:name' => sub {
    return "Hola " . params->{name};
};

get '/page' => sub {
    return $pager->fillin_create_page;
};

post '/page' => sub {
    my $params = params;
    my $id = $mojito->create_page($params);
    redirect "${base_url}page/${id}/edit";
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
    my $page = $mojito->update_page(scalar params);
    my $id = params->{id};
    redirect "${base_url}page/${id}";
};

get '/page/:id/delete' => sub {
    my $id = params->{id};
    $pager->delete($id);
    redirect $base_url . 'recent';
};

get '/recent' => sub {
    my $want_delete_link = 1;
    my $links            = $pager->get_most_recent_links($want_delete_link);
    return $links;
};

get '/' => sub {
    my $output = $pager->home_page;
    my $links  = $pager->get_most_recent_links;
    $output =~ s/(<section\s+id="recent_area".*?>)<\/section>/$1${links}<\/section>/si;
    return $output;
};

dance;
