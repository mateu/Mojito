use strictures 1;
use 5.010;
use Data::Dumper::Concise;

my $messages = [
#    {
#        name           => 'ViewPage',
#        request_method => 'get',
#        route          => '/page/:id',
#        response       => '$mojito->view_page($params)',
#        response_type  => 'html'
#    },
#    {
#        name           => 'EditPage',
#        request_method => 'get',
#        route          => '/page/:id/edit',
#        response       => '$mojito->edit_page_form($params)',
#        response_type  => 'html',
#    },
#    {
#        name           => 'EditPage',
#        request_method => 'post',
#        route          => '/page/:id/edit',
#        response       => '$mojito->edit_page($params)',
#        response_type  => 'redirect',
#    },
#    {
#        name           => 'SearchPage',
#        request_method => 'get',
#        route          => '/search/:word',
#        response       => '$mojito->search($params)',
#        response_type  => 'html',
#    },
    {
        name           => 'DiffPage',
        request_method => 'get',
        route          => '/page/:id/diff',
        response       => '$mojito->view_page_diff($params)',
        response_type  => 'html',
    },
];

foreach my $message (@{$messages}) {
    say transform_mojo($message);
}
foreach my $message (@{$messages}) {
    say transform_dancer($message);
}
foreach my $message (@{$messages}) {
    say transform_tatsumaki($message);
}
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
        $response = '$self->redirect_to(' . $message_response .')';
    }
    my $place_holders;
    if (my @holders = $message->{route}  =~ m/\/\:(\w+)/ ) {
        foreach my $holder (@holders) {
            $place_holders .=  '$params->{' . $holder  . '} = $self->param(\'' . $holder . "');\n";
        }
#       print Dumper \@holders;
#       print $place_holders;
    }
    chomp($place_holders);

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
