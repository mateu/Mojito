package ParsePage;
use Moose;
use strictures;
use 5.010;
use namespace::autoclean;
use HTML::HTML5::Parser;
use Data::Dumper::Concise;

has 'page' => (
	is       => 'rw',
	isa      => 'Str',
	required => 1,
);
has 'section_open_regex' => (
	is       => 'ro',
	isa      => 'RegexpRef',
	init_arg => undef,
	default  => sub { qr/<sx c=(?:'|")?\w+(?:'|")?/ },
);
has 'section_close_regex' => (
	is       => 'ro',
	isa      => 'RegexpRef',
	init_arg => undef,
	default  => sub { qr(</sx>) },
);

sub has_nested_section
{
	my ($self) = @_;

	my $section_open_regex  = $self->section_open_regex;
	my $section_close_regex = $self->section_close_regex;

	my @stuff_between_section_opens =
	  $self->page =~ m/${section_open_regex}(.*?)${section_open_regex}/sg;

	# If when find a section ending tag in the middle of the two consecutive
	# opening section tags then we know first section has been closed and thus
	# does NOT contain a nested section.
	my $has_nested_section = 0;
	foreach my $tweener (@stuff_between_section_opens)
	{

		#say "match tween: $tweener";
		if ($tweener =~ m/<\/sx>/)
		{

			# The tweener section could cause us to think we're not nested
			# due to an nested section of the general type (not the class=mc_ type)
			# In this case we need to count the number of open and closed sections
			# If they are the same then we dont' have </sec> left over to close the first
			# and thus we have a nest.
			my @opens  = $tweener =~ m/(<sx[^>]*>)/sg;
			my @closes = $tweener =~ m/(<\/sx>)/sg;
			if (scalar @opens == scalar @closes)
			{

				#warn "has nested section with content: $tweener";
				return 1;
			}
		}
		else
		{

			#warn "has nested section with content: $tweener";
			return 1;
		}
	}

	return 0;
}

sub add_implicit_sections
{
	my ($self) = @_;

	my $page                = $self->page;
	my $section_open_regex  = $self->section_open_regex;
	my $section_close_regex = $self->section_close_regex;

	# look behinds need a fixed distance.  Let's provide them one by collapsing
	# whitespace in just the right spot, betweeen <sx  and c=
	$page =~ s/(<sx\s+c=)/<sx c=/sgi;

	# Add implicit sections in between explicit sections (if needed)
	$page =~
	  s/($section_close_regex)(.*?\S.*?)($section_open_regex)/$1\n<sx c=Implicit>$2<\/sx>\n$3/sig;

	# Add implicit section at the beginning (if needed)
	$page =~ s/(?<!<sx c=)(<sx c=)/<\/sx>\n$1/si;
	$page = "\n<sx c=Implicit>\n${page}";

	# Add implicit section at the end (if needed)
	$page =~ s/(<\/sx>)(?!.*<\/sx>)/$1\n<sx c=Implicit>/si;
	$page .= '</sx>';

	# cut empty implicits
	$page =~ s/<sx c=Implicit>\s*<\/sx>//sig;

	#			say "PREMATCH: ", ${^PREMATCH};
	#	    	say "MATCH:  ${^MATCH}";
	#	    	say "POSTMATCH: ", ${^POSTMATCH};
	#	    	say "page: $page";

	return $page;
}

sub parse_html5
{
	my ($self, $html5) = @_;

	my $parser         = HTML::HTML5::Parser->new;
	my $doc            = $parser->parse_string($html5);
	my $tagname        = 'sx';
	my $attribute_name = 'c';
	my $nodelist       = $doc->getElementsByTagName('sx');
	while (my $node = $nodelist->shift)
	{
		if ($node->hasChildNodes())
		{
			my $first_child = $node->firstChild;
			print "Child node toString: ", $node->toString;
		}

		if ($node->nodeName eq 'sx')
		{
			print "\n\nnode name: ", Dumper $node->nodeName;
			if ($node->getAttribute($attribute_name))
			{
				print "node class attribute value: ",
				  $node->getAttribute($attribute_name), "\n";
			}
			else
			{
				say "Resotring to document default format";
			}

			#print "node text content: ", $node->textContent;
			#print "node toString: ", $node->toString;
		}
	}
}

__PACKAGE__->meta->make_immutable;
1
