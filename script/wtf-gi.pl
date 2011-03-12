use 5.010;

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
];

foreach my $message (@{$messages}) {
    say transform_mojo($message);
}

sub transform_dancer {
    my $message = shift;

    if ( $message->{response_type} eq 'html' ) {
        $message->{response} = 'return ' . $message->{response};
    }
    elsif ( $message->{response_type} eq 'redirect' ) {
        $message->{response} = 'redirect ' . $message->{response};
    }

    my $route_body = <<"END_BODY";
$message->{request_method} $message->{route} => sub {
    my \$params = scalar params;
    $message->{response};
};
END_BODY

    return $route_body;
}

sub transform_mojo {
    my $message = shift;

    if ( $message->{response_type} eq 'html' ) {
        $message->{response} = '$self->render( text => ' . $message->{response} . ')';
    }
    elsif ( $message->{response_type} eq 'redirect' ) {
        $message->{response} = '$self->redirect_to(' . $message->{response} .')';
    }

    my $route_body = <<"END_BODY";
$message->{request_method} $message->{route} => sub {
    my \$params = scalar params;
    $message->{response};
};
END_BODY

}
