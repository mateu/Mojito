use strictures 1;
use 5.010;
use Getopt::Long;
use Data::Dumper::Concise;

=head1 Usage

    perl -Ilib script/wtf-gi.pl --name PublishPage --transform web_simple
    
=cut

my ($name, $transform);

my $result = GetOptions(
    'name|n=s'      => \$name,
    'transform|t=s' => \$transform,
);
# prefix tranform
$transform = 'transform_' . $transform;

my $messages = [

    {
        name           => 'ViewPage',
        request_method => 'get',
        route          => '/page/:id',
        response       => '$mojito->view_page($params)',
        response_type  => 'html'
    },
    {
        name           => 'EditPage',
        request_method => 'get',
        route          => '/page/:id/edit',
        response       => '$mojito->edit_page_form($params)',
        response_type  => 'html',
    },
    {
        name           => 'EditPage',
        request_method => 'post',
        route          => '/page/:id/edit',
        response       => '$mojito->edit_page($params)',
        response_type  => 'redirect',
    },
    {
        name           => 'SearchPage',
        request_method => 'get',
        route          => '/search/:word',
        response       => '$mojito->search($params)',
        response_type  => 'html',
    },
    {
        name           => 'SearchPage',
        request_method => 'post',
        route          => '/search',
        response       => '$mojito->search($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'DiffPage',
        request_method => 'get',
        route          => '/page/:id/diff',
        response       => '$mojito->view_page_diff($params)',
        response_type  => 'html',
    },
    {
        name           => 'CollectPage',
        request_method => 'get',
        route          => '/collect',
        response       => '$mojito->collect_page_form($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CollectPage',
        request_method => 'post',
        route          => '/collect',
        response       => '$mojito->collect($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CollectionsIndex',
        route          => '/collections',
        request_method => 'get',
        response       => '$mojito->collections_index()',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'CollectionPage',
        route          => '/collection/:id',
        request_method => 'get',
        response       => '$mojito->collection_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'SortCollection',
        route          => '/collection/:id/sort',
        request_method => 'get',
        response       => '$mojito->sort_collection_form($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'SortCollection',
        route          => '/collection/:id/sort',
        request_method => 'post',
        response       => '$mojito->sort_collection($params)',
        response_type  => 'redirect',
        status_code    => 301,
    },
    {
        name           => 'DiffPage',
        route          => '/page/:id/diff/:m/:n',
        request_method => 'get',
        response       => '$mojito->diff_page($params)',
        response_type  => 'html',
        status_code    => 200,
    },
    {
        name           => 'PublishPage',
        route          => '/page/:id/publish',
        request_method => 'post',
        response       => '$mojito->publish_page($params)',
        response_type  => 'redirect',
        status_code    => 301,
    },
];

sub get_message_by_name {
    my $name = shift;
    my @pages = grep { $_->{name} =~ m/^$name$/ } @{$messages};
    die "NEED exactly one message by name. Found ", scalar @pages if scalar @pages != 1;
    return $pages[0];
}

my %transforms = (
    transform_web_simple => \&transform_web_simple,
    transform_dancer     => \&transform_dancer,
    transform_mojo       => \&transform_mojo,
    transform_tatsumaki  => \&transform_tatsumaki,
);

sub transform_message_by_framework {
    my ( $message, $framework ) = ( shift, shift );
    my $transformer = 'transform_' . $framework;
    say $transforms{$transformer}->($message);
}

if ($name) {
    warn "name: $name";
    $messages = [ (get_message_by_name($name)) ];
}
if ($transform) {
    warn "transform: $transform";
    %transforms = map {$_, $transforms{$_}} grep { $_ eq $transform; } keys %transforms;
}
foreach my $message ( @{$messages} ) {
    foreach my $transform (keys %transforms) {
        say $transforms{$transform}->($message);
    }
}

#foreach my $message ( @{$messages} ) {
#    say transform_dancer($message);
#}
#foreach my $message ( @{$messages} ) {
#    say transform_tatsumaki($message);
#}
#foreach my $message ( @{$messages} ) {
#    say transform_web_simple($message);
#}

sub transform_dancer {
    my $message = shift;

    my $response;
    if ( $message->{response_type} eq 'html' ) {
        $response = 'return ' . $message->{response};
    }
    elsif ( $message->{response_type} eq 'redirect' ) {
        $response = 'redirect ' . $message->{response};
    }

    my $route_body = <<"END_BODY";
$message->{request_method} '$message->{route}' => sub {
    my \$params = scalar params;
    $response;
};
END_BODY

    return $route_body;
}

sub transform_mojo {
    my $message = shift;

    my $message_response = $message->{response};
    $message_response =~ s/\$//;
    my $response;
    if ( $message->{response_type} eq 'html' ) {
        $response = '$self->render( text => $self->' . $message_response . ' )';
    }
    elsif ( $message->{response_type} eq 'redirect' ) {
        $response = '$self->redirect_to(' . $message_response . ')';
    }
    my $place_holders;
    if ( my @holders = $message->{route} =~ m/\/\:(\w+)/ ) {
        foreach my $holder (@holders) {
            $place_holders .=
                '$params->{' 
              . $holder
              . '} = $self->param(\''
              . $holder . "');\n";
        }

        #       print Dumper \@holders;
        #       print $place_holders;
    }
    if ($place_holders) {
        chomp($place_holders);
    }
    else {
        $place_holders = "# no place holders";
    }

    my $route_body = <<"END_BODY";
$message->{request_method} '$message->{route}' => sub {
    my (\$self) = (shift);
    my \$params;
    $place_holders
    $response;
};
END_BODY

}

sub transform_tatsumaki {
    my $message = shift;

    my $message_response = $message->{response};
    $message_response =~ s/\$mojito/\$self->request->env->{'mojito'}/;
    my $route_body = <<"END_BODY";
package $message->{name};
use parent qw(Tatsumaki::Handler);

sub $message->{request_method} {
    my ( \$self, \$id ) = \@_;
    my \$params;
    \$params->{'id'} = \$id;
    \$self->write($message_response);
}
END_BODY
    return $route_body;
}

sub transform_web_simple {
    my $message = shift;

    my $message_response = $message->{response};
    my $content_type     = "['Content-type', ";
    $content_type .= "'text/html']" if ( $message->{response_type} eq 'html' );
    my $request_method = uc( $message->{request_method} );
    my $message_route  = $message->{route};
    my ( $args, $params ) = route_handler( $message_route, 'simple' );
    $message_route =~ s/\:\w+/*/g;
    $message_route .= ' + %*' if ( $request_method eq 'POST' );
    my $route_body;
    if ($message->{response_type} eq 'redirect') {
        $route_body = <<"END_BODY";
sub ( $request_method + $message_route ) {
    my (\$self, $args) = \@_;
    $params
    my \$redirect_url = $message_response;
    [ 301, [ Location => \$redirect_url ], [] ];
},

END_BODY
    }
    else {
        $route_body = <<"END_BODY";
sub ( $request_method + $message_route ) {
    my (\$self, $args) = \@_;
    $params
    my \$output = $message_response;
    [ $message->{status_code}, $content_type, [\$output] ];
},

END_BODY
    }
    return $route_body;
}

sub route_handler {
    my ( $route, $framework ) = ( shift, shift );

    my ( $args, $params );
    given ($framework) {
        when (/simple/i) {

            # find placeholders
            my @place_holders = $route =~ m/\:(\w+)/ig;
            my @args = map { '$' . $_ } @place_holders;
            $args = join ', ', @args;
            my @params =
              map { '$params->{' . $_ . '} = $' . $_ . ';' } @place_holders;
            $params = join "\n    ", @params;

            #            say "args: $args; params: $params";
        }
        when (/tatsu/i) {

        }
    }
    return ( $args, $params );
}
