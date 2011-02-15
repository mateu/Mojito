package Fixture;
use 5.010;

$implicit_section = <<'END';
h1. Greetings

<sx c=Perl>
use Modern::Perl;
say 'something';
</sx>

Implicit Section

<sx c="JavaScript">
function () { var one = 1 }
</sx>

Stuff After

END

$nested_section = <<'END';
	   <sx c=SQL>Bon dia<section>heya</section><section>otra</section><sx c=squared>I'm nested</sx></sx>
END

$not_nested_section = <<'END';
       <sx c=SQL>Hola</sx><sx c=SQL>Not Nested</sx>
END

$explicit_section = <<'END';


    
    
        
       <sx c="mc_SQL">Hola
       </sx>
       

    
    
END
$implicit_normal_section = <<'END';
<sx c=Python>def: init</sx><section>What happens here?</section><sx c=PHP>a[3]</sx>
END
$implicit_normal_starting_section = <<'END';
    Yeah
<section>Heya</section>
OK
<sx c=Python>def: init</sx>
<section>What happens here?</section>
How about here?
<sx c=PHP>a[3]</sx>
Dirty
<section>The End</section>
Nasty test
END

$parsed_implicit_section = <<'END';

<sx c=Implicit>
h1. Greetings

</sx>
<sx c=Perl>
use Modern::Perl;
say 'something';
</sx>
<sx c=Implicit>

Implicit Section

</sx>
<sx c="JavaScript">
function () { var one = 1 }
</sx>
<sx c=Implicit>

Stuff After

END
$parsed_implicit_section .= '</sx>';

$parsed_implicit_normal_section = <<'END';


<sx c=Python>def: init</sx>
<sx c=Implicit><section>What happens here?</section></sx>
<sx c=PHP>a[3]</sx>
END

$parsed_implicit_normal_starting_section = <<'END';

<sx c=Implicit>
    Yeah
<section>Heya</section>
OK
</sx>
<sx c=Python>def: init</sx>
<sx c=Implicit>
<section>What happens here?</section>
How about here?
</sx>
<sx c=PHP>a[3]</sx>
<sx c=Implicit>
Dirty
<section>The End</section>
Nasty test
END
$parsed_implicit_normal_starting_section .= '</sx>';

$simple_implicit_section = <<'END';
Hola Mon.
END

$parsed_simple_implicit_section = <<'END';

<sx c=Implicit>
Hola Mon.
END
$parsed_simple_implicit_section .= '</sx>';

$simple_non_implicit_section = <<'END';
<sx c=Perl>say "Bom dia";</sx>
END

$parsed_simple_non_implicit_section = <<'END';


<sx c=Perl>say "Bom dia";</sx>
END

$sections  = 
[
  {
    class => "Implicit",
    content => "\n    Yeah\n<section>Heya</section>\nOK\n"
  },
  {
    class => "Python",
    content => "def: init"
  },
  {
    class => "Implicit",
    content => "\n<section>What happens here?</section>\nHow about here?\n"
  },
  {
    class => "PHP",
    content => "a[3]"
  },
  {
    class => "Implicit",
    content => "\nDirty\n<section>The End</section>\nNasty test\n"
  }
];
$page_structure = {
    default_format => "HTML",
    sections       => [
        {
            class   => "Implicit",
            content => "\n    Yeah\n<section>Heya</section>\nOK\n"
        },
        {
            class   => "Python",
            content => "def: init"
        },
        {
            class => "Implicit",
            content =>
              "\n<section>What happens here?</section>\nHow about here?\n"
        },
        {
            class   => "PHP",
            content => "a[3]"
        },
        {
            class   => "Implicit",
            content => "\nDirty\n<section>The End</section>\nNasty test\n"
        }
    ],
};

$prettyprint =<<'END_WIKI';
h1. Indiana

h2. Bloomington

A rocking town, home of the Hoosiers.

<sx c=h>
my $house = 'nice';
use Me;

sub func () {
    my $self = shift;
    return 1;
}
</sx>

<pre class="prettyprint linenums">
my $house = 'nice';
use Me;

sub func () {
    my $self = shift;
    return 1;
}
</pre>
END_WIKI


1;
