use strictures 1;
use 5.010;
use Test::More;
use Test::Differences;
use ParsePage;

# Fixtures defined in BEGIN
my ($simple_implicit_section, $simple_non_implicit_section);
my (
	$nested_section,   $not_nested_section, $implicit_section,
	$explicit_section, $implicit_normal_section, $implicit_normal_starting_section
);
my ($parsed_section_page, $parsed_implicit_section, $parsed_implicit_normal_section,
 $parsed_implicit_normal_starting_section, $parsed_simple_implicit_section, $parsed_simple_non_implicit_section);

my $parser = ParsePage->new(page => $nested_section);
ok($parser->has_nested_section, 'nested section');

# Change content to not be nested
$parser->page($not_nested_section);
ok(!$parser->has_nested_section, 'not nested section');

$parser->page($simple_non_implicit_section);
my $sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $parsed_simple_non_implicit_section, 'simple non-implicit section');

$parser->page($simple_implicit_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $parsed_simple_implicit_section, 'simple implicit section');

# Change content to test implicit section addition
$parser->page($implicit_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $parsed_implicit_section, 'implicit section');
$parser->parse_html5($sectioned_page);

# Change content to test implicit section with a normal section
$parser->page($implicit_normal_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $parsed_implicit_normal_section, 'implicit normal section');

# Change content to test implicit section with a normal starting section
$parser->page($implicit_normal_starting_section);
$sectioned_page = $parser->add_implicit_sections;
eq_or_diff($sectioned_page, $parsed_implicit_normal_starting_section, 'implicit normal starting section');
#$parser->parse_html5($sectioned_page);
done_testing();

sub BEGIN
{
	$implicit_section = <<'END';
h1. Greetings

<sx c=Perl>
use Modern::Perl;
say 'something';
</sx>

Implicit Section

<sx c="mc_JS">
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

$parsed_implicit_section =<<'END';

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
<sx c="mc_JS">
function () { var one = 1 }
</sx>
<sx c=Implicit>

Stuff After

END
$parsed_implicit_section .= '</sx>';


$parsed_implicit_normal_section =<<'END';


<sx c=Python>def: init</sx>
<sx c=Implicit><section>What happens here?</section></sx>
<sx c=PHP>a[3]</sx>
END

$parsed_implicit_normal_starting_section =<<'END';

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

$simple_implicit_section =<<'END';
Hola Mon.
END

$parsed_simple_implicit_section=<<'END';

<sx c=Implicit>
Hola Mon.
END
$parsed_simple_implicit_section .= '</sx>';

$simple_non_implicit_section=<<'END';
<sx c=Perl>say "Bom dia";</sx>
END

$parsed_simple_non_implicit_section=<<'END';


<sx c=Perl>say "Bom dia";</sx>
END
}