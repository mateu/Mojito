use strictures 1;
package Mojito::Template::Role::Publish;
use Moo::Role;
use Mojito::Page::Publish;

has publisher => (
    is => 'ro',
    isa => sub { die "Need a Page::Publish object" unless $_[0]->isa('Mojito::Page::Publish') },
    lazy => 1,
    builder => '_build_publisher',
);
sub _build_publisher {
    return Mojito::Page::Publish->new;
}
has publish_form => (
    is => 'rw',
    lazy => 1,
    builder => '_build_publish_form',
);
sub _build_publish_form {
    my $self = shift;
  
    return if not defined $self->publisher->target_base_url;  
    my $target_base_url = $self->publisher->target_base_url;
    my $user = $self->publisher->user;
    my $password = $self->publisher->password;
    my $form =<<"END_FORM";
<div class="demo">

<div id="dialog-form" title="Publish this page">
    <form>
    <fieldset>
    <table>
    <tr>
        <td><label for="name">Page Name:</label></td>
        <td><input type="text" name="name" id="name" class="text ui-widget-content ui-corner-all" size="48" required /></td>
    </tr>
        <td><label for="target_base_url">Pub Base:</label></td>
        <td><input type="text" name="target_base_url" id="target_base_url" value="$target_base_url" class="text ui-widget-content ui-corner-all" size="48" required /></td>
    </tr>
        <td><label for="user">User:</label>
        <td><input type="text" name="user" id="user" value="$user" class="text ui-widget-content ui-corner-all" required /></td>
    </tr>        
        <td><label for="password">Password</label>
        <td><input type="password" name="password" id="password" value="$password" class="text ui-widget-content ui-corner-all" required /></td>
    </tr>
    </table>
    </fieldset>
    </form>
</div>
<button id="publish-page">Publish</button>

</div>
END_FORM
 
    return $form;
}

1
