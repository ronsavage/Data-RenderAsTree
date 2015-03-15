package Data::RenderAsTree;

use strict;
use warnings;

use Moo;

use Scalar::Util qw/blessed reftype/;

use Set::Array;

use Text::Truncate; # For truncstr().

use Tree::DAG_Node;

use Types::Standard qw/Any Bool Int Object Str/;

has attributes =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

has index_stack =>
(
	default   => sub{return Set::Array -> new},
	is        => 'rw',
	isa       => Object,
	required => 0,
);

has max_key_length =>
(
	default   => sub{return 10_000},
	is        => 'rw',
	isa       => Int,
	required => 0,
);

has max_value_length =>
(
	default   => sub{return 10_000},
	is        => 'rw',
	isa       => Int,
	required => 0,
);

has node_stack =>
(
	default   => sub{return Set::Array -> new},
	is        => 'rw',
	isa       => Object,
	required => 0,
);

has root =>
(
	default   => sub{return ''},
	is        => 'rw',
	isa       => Any,
	required => 0,
);

has title =>
(
	default   => sub{return 'Root'},
	is        => 'rw',
	isa       => Str,
	required => 0,
);

has uid =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Bool,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub BUILD
{
	my($self)         = @_;
	my($key_length)   = $self -> max_key_length;
	my($value_length) = $self -> max_value_length;

	$self -> max_key_length(30)   if ( ($key_length   < 1) || ($key_length   > 10_000) );
	$self -> max_value_length(30) if ( ($value_length < 1) || ($value_length > 10_000) );

} # End of BUILD.

# ------------------------------------------------

sub _add_daughter
{
	my($self, $name, $attributes)  = @_;

	print "Entered _add_daughter($name, $attributes)\n" if ($self -> verbose);

	$attributes        = {} if (! $attributes);
	$$attributes{name} = $name;
	$$attributes{uid}  = $self -> uid($self -> uid + 1);
	$name              = truncstr($name, $self -> max_key_length);
	my($node)          = Tree::DAG_Node -> new({name => $name, attributes => $attributes});
	my($tos)           = $self -> node_stack -> length - 1;

	die "Stack is empty\n" if ($tos < 0);

	${$self -> node_stack}[$tos] -> add_daughter($node);

	return $node;

} # End of _add_daughter.

# ------------------------------------------------

sub _process_arrayref
{
	my($self, $value) = @_;

	print "Entered _process_arrayref($value)\n" if ($self -> verbose);

	my($index)  = $self -> index_stack -> last;
	my($parent) = $self -> _process_scalar("$index = []", 'ARRAY');

	$self -> node_stack -> push($parent);

	$index = -1;

	my($bless_type);
	my($node);
	my($ref_type);

	for my $item (@$value)
	{
		$index++;

		$bless_type = blessed($item) || '';
		$ref_type   = reftype($item) || 'VALUE';

		if ($bless_type)
		{
			$self -> node_stack -> push($self -> _process_scalar("Class = $bless_type", 'BLESS') );
		}

		if ($ref_type eq 'ARRAY')
		{
			$self -> index_stack -> push($index);
			$self -> _process_arrayref($item);

			$index = $self -> index_stack -> pop;
		}
		elsif ($ref_type eq 'HASH')
		{
			$self -> _process_hashref($item);
		}
		elsif ($ref_type eq 'SCALAR')
		{
			$self -> _process_scalar($item);
		}
		else
		{
			$self -> _process_scalar("$index = " . (defined($item) ? truncstr($item, $self -> max_value_length) : 'undef') );
		}

		$node = $self -> node_stack -> pop if ($bless_type);
	}

	$node = $self -> node_stack -> pop;

} # End of _process_arrayref;

# ------------------------------------------------

sub _process_hashref
{
	my($self, $data) = @_;
	my($index) = -1;

	print "Entered _process_hashref($data)\n" if ($self -> verbose);

	my($parent) = $self -> _process_scalar('{}', 'HASH');

	$self -> node_stack -> push($parent);

	my($bless_type);
	my($node);
	my($ref_type);
	my($value);

	for my $key (sort keys %$data)
	{
		$index++;

		$value      = $$data{$key};
		$bless_type = blessed($value) || '';
		$ref_type   = reftype($value) || 'VALUE';
		$key        = "$key = {}" if ($ref_type eq 'HASH');

		# Values for use_value:
		# 0: No, the value of value is undef. Ignore it.
		# 1: Yes, The value may be undef, but use it.

		$node = $self -> _add_daughter
			(
				$key,
				{type => $ref_type, use_value => 1, value => $value}
			);

		if ($bless_type)
		{
			$self -> node_stack -> push($node);

			$node = $self -> _process_scalar("Class = $bless_type", 'BLESS');
		}

		$self -> node_stack -> push($node);

		if ($ref_type eq 'ARRAY')
		{
			$self -> index_stack -> push($index);
			$self -> _process_arrayref($value);

			$index = $self -> index_stack -> pop;
		}
		elsif ($ref_type =~ /CODE|REF|SCALAR|VALUE/)
		{
			# Do nothing. sub _process_tree() will combine $key and $value.
		}
		elsif ($ref_type eq 'HASH')
		{
			$self -> _process_hashref($value);
		}
		else
		{
			die "Sub _process_hashref() cannot handle the ref_type: $ref_type. \n";
		}

		$node = $self -> node_stack -> pop;
		$node = $self -> node_stack -> pop if ($bless_type);

		# TODO: Why don't we need this in _process_arrayref()?
		# And ... Do we need to check after each pop above?

		$self -> node_stack -> push($self -> root) if ($node -> is_root);
	}

	$self -> node_stack -> pop;

} # End of _process_hashref.

# ------------------------------------------------

sub _process_scalar
{
	my($self, $value, $type) = @_;
	$type ||= 'SCALAR';

	print "Entered _process_scalar($value, $type)\n" if ($self -> verbose);

	# Values for use_value:
	# 0: No, the value of value is undef. Ignore it.
	# 1: Yes, The value may be undef, but use it.

	return $self -> _add_daughter
			(
				$value,
				{type => $type, use_value => 0, value => undef}
			);

} # End of _process_scalar.

# ------------------------------------------------

sub process_tree
{
	my($self) = @_;

	if ($self -> verbose)
	{
		print "Entered process_tree(). Printing tree before walk_down ...\n";
		print join("\n", @{$self -> root -> tree2string({no_attributes => 0})}), "\n";
		print '-' x 50, "\n";
	}

	my($attributes);
	my($ignore_value, $id);
	my($key);
	my($name);
	my($ref_type);
	my($type);
	my($uid, $use_value);
	my($value);

	$self -> root -> walk_down
	({
		callback => sub
		{
			my($node, $opt) = @_;

			# Ignore the root, and keep walking.

			return 1 if ($node -> is_root);

			$name           = $node -> name;
			$attributes     = $node -> attributes;
			$type           = $$attributes{type};
			$ref_type       = ($type =~ /^(\w+)/) ? $1 : $type; # Ignores '(0x12345678)'.
			$uid            = $$attributes{uid};
			$use_value      = $$attributes{use_value};
			$value          = $$attributes{value};
			$key            = "$ref_type $uid";

			print "Key: $key. Name: $name. \n";

			if (defined($value) && $$opt{seen}{$value})
			{
				$id = ( ($ref_type eq 'SCALAR') || ($key =~ /^ARRAY|BLESS|HASH/) ) ? $key : "$key -> $$opt{seen}{$value}";
			}
			elsif ($ref_type eq 'CODE')
			{
				$id   = $key;
				$name = defined($value) ? "$name = $value" : $name;
			}
			elsif ($ref_type eq 'REF')
			{
				$id  = defined($value) ? $$opt{seen}{$$value} ? "$key -> $$opt{seen}{$$value}" : $key : $key;
			}
			elsif ($ref_type eq 'VALUE')
			{
				$id   = $key;
				$name = defined($name) ? $name : 'undef';
				$name .= ' = ' . truncstr(defined($value) ? $value : 'undef', $self -> max_value_length) if ($use_value);
			}
			elsif ($ref_type eq 'SCALAR')
			{
				$id   = $key;
				$name = defined($name) ? $name : 'undef';
				$name .= ' = ' . truncstr(defined($value) ? $value : 'undef', $self -> max_value_length) if ($use_value);
			}
			else
			{
				$id = $key;
			}

			$node -> name("$name [$id]");

			$$opt{seen}{$value} = $id if (defined($value) && ! defined $$opt{seen}{$value});

			# Keep walking.

			return 1;
		},
		_depth => 0,
		seen   => {},
	});

} # End of process_tree.

# ------------------------------------------------

sub run
{
	my($self, $s) = @_;
	$s = defined($s) ? $s : 'undef';

	$self -> root
	(
		Tree::DAG_Node -> new
		({
			attributes => {type => '', uid => $self -> uid, value => ''},
			name       => $self -> title,
		})
	);
	$self -> node_stack -> push($self -> root);
	$self -> index_stack -> push(0);

	my($bless_type) = blessed($s) || '';
	my($ref_type)   = reftype($s) || 'VALUE';

	if ($bless_type)
	{
		$self -> node_stack -> push($self -> _process_scalar("Class = $bless_type", 'BLESS') );
	}

	if ($ref_type eq 'ARRAY')
	{
		$self -> _process_arrayref($s);
	}
	elsif ($ref_type eq 'HASH')
	{
		$self -> _process_hashref($s);
	}
	elsif ($ref_type =~ /REF|SCALAR|VALUE/)
	{
		$self -> _process_scalar($s, $ref_type);
	}
	else
	{
		die "Sub run() cannot handle the ref_type: $ref_type. \n";
	}

	$self -> process_tree;

	# Clean up in case user reuses this object.

	$self -> node_stack -> pop;
	$self -> index_stack -> pop;
	$self -> node_stack -> pop if ($bless_type);
	$self -> uid(0);

	return $self -> root -> tree2string({no_attributes => 1 - $self -> attributes});

} # End of run.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Data::RenderAsTree> - Render any data structure as an object of type Tree::DAG_Node

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Data::RenderAsTree;

	use Tree::DAG_Node;

	# ------------------------------------------------

	my($sub) = sub {};
	my($s)   =
	{
		A =>
		{
			a      => {},
			bbbbbb => $sub,
			c123   => $sub,
			d      => \$sub,
		},
		B => [qw(element_1 element_2 element_3)],
		C   =>
		{
	 		b =>
			{
				a =>
				{
					a => {},
					b => sub {},
					c => '429999999999999999999999999999999999999999999999',
				}
			}
		},
		DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD => 'd',
		Object     => Tree::DAG_Node -> new({name => 'A tree', attributes => {one => 1} }),
		Ref2Scalar => \'s', # Use ' in comment for UltraEdit hiliting.
	};
	my($result) = Data::RenderAsTree -> new
		(
			attributes       => 0,
			max_key_length   => 25,
			max_value_length => 20,
			title            => 'Synopsis',
			verbose          => 0,
		) -> run($s);

	print join("\n", @$result), "\n";

This is the output of scripts/synopsis.pl:

	Synopsis
	    |--- {} [HASH 1]
	         |--- A = {} [HASH 2]
	         |    |--- {} [HASH 3]
	         |         |--- a = {} [HASH 4]
	         |         |    |--- {} [HASH 5]
	         |         |--- bbbbbb = CODE(0x1c93e30) [CODE 6]
	         |         |--- c123 [CODE 7 -> CODE 6]
	         |         |--- d [REF 8 -> CODE 6]
	         |--- B [ARRAY 9]
	         |    |--- 1 = [] [ARRAY 10]
	         |         |--- 0 = element_1 [SCALAR 11]
	         |         |--- 1 = element_2 [SCALAR 12]
	         |         |--- 2 = element_3 [SCALAR 13]
	         |--- C = {} [HASH 14]
	         |    |--- {} [HASH 15]
	         |         |--- b = {} [HASH 16]
	         |              |--- {} [HASH 17]
	         |                   |--- a = {} [HASH 18]
	         |                        |--- {} [HASH 19]
	         |                             |--- a = {} [HASH 20]
	         |                             |    |--- {} [HASH 21]
	         |                             |--- b = CODE(0x2475c68) [CODE 22]
	         |                             |--- c = 42999999999999999... [VALUE 23]
	         |--- DDDDDDDDDDDDDDDDDDDDDD... = d [VALUE 24]
	         |--- Object = {} [HASH 25]
	         |    |--- Class = Tree::DAG_Node [BLESS 26]
	         |         |--- {} [HASH 27]
	         |              |--- attributes = {} [HASH 28]
	         |              |    |--- {} [HASH 29]
	         |              |         |--- one = 1 [VALUE 30]
	         |              |--- daughters [ARRAY 31]
	         |              |    |--- 1 = [] [ARRAY 32]
	         |              |--- mother = undef [VALUE 33]
	         |              |--- name = A tree [VALUE 34]
	         |--- Ref2Scalar = SCALAR(0x230a230) [SCALAR 35]

=head1 Description

L<Data::RenderAsTree> provides a mechanism to display a Perl data structure.

The data supplied to L</run($s)> is stored in an object of type L<Tree::DAG_Node>.

C<run()> returns an arrayref by calling C<Tree::DAG_Node>'s C<tree2string()> method, so you can
just print the return value as a string by using code as in synopsis.pl above.

It also means you can display as much or as little of the result as you wish, by printing a range
of array elements.

Hash key lengths can be limited by L</max_key_length($int)>, and hash value lengths can be limited
by L</max_value_length($int)>.

For sub-classing, see L</process_tree()>.

The module serves as a simple replacement for L<Data::TreeDumper>, but without the huge set of
features.

For sample code, see these programs in the scripts/ directory of the distro:

=over 4

=item o array.pl

=item o bless.pl

=item o hash.pl

=item o mixup.pl

=item o ref.pl

=item o synopsis.pl

=back

See also the test files t/*.t, which are basically copies of the above. And that means, like the
*.pl above, all expected output is given in the source code.

Lastly, see the L</FAQ> for details such as how to process the output tree yourself.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Data::RenderAsTree> as you would for any C<Perl> module:

Run:

	cpanm Data::RenderAsTree

or run:

	sudo cpan Data::RenderAsTree

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($g2m) = Data::RenderAsTree -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Data::RenderAsTree>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</max_key_length([$int])>]):

=over 4

=item o attributes => $Boolean

This is a debugging aid. When set to 1, metadata attached to each tree node is included in the
output.

Default: 0.

=item o max_key_length => $int

Use this to limit the lengths of hash keys.

Default: 10_000.

=item o max_value_length => $int

Use this to limit the lengths of hash values.

Default: 10_000.

=item o title => $s

Use this to set the name of the root node in the tree.

Default: 'Root'.

=back

=head1 Methods

=head2 attributes([$Boolean])

Here, the [] indicate an optional parameter.

Gets or sets the attributes option.

Note: The value passed to L<Tree::DAG_Node>'s C<tree2string()> method is (1 - $Boolean).

C<attributes> is a parameter to L</new()>.

=head2 max_key_length([$int])

Here, the [] indicate an optional parameter.

Gets or sets the maximum string length displayed for hash keys.

C<max_key_length> is a parameter to L</new()>.

=head2 max_key_length([$int])

Here, the [] indicate an optional parameter.

Gets or sets the maximum string length displayed for hash values.

C<max_key_length> is a parameter to L</new()>.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 process_tree()

Just before L</run($s)> returns, it calls C<process_tree()>, while walks the tree and adjusts
various bits of data attached to each node in the tree.

If sub-classing this module, e.g. to change the precise text displayed, I recommend concentrating
your efforts on this method.

Alternately, see the answer to the first question in the L</FAQ>.

=head2 root()

Returns the root node in the tree, which is an object of type L<Tree::DAG_Node>.

=head2 run($s)

Renders $s into an object of type L<Tree::DAG_Node>.

Returns an arrayref after calling the C<tree2string()> method for L<Tree::DAG_Node>.

See L</Synopsis> for typical usage.

=head2 title([$s])

Here, the [] indicate an optional parameter.

Gets or sets the title, which is the name of the root node in the tree.

C<title> is a parameter to L</new()>.

=head2 verbose([$Boolean])

Here, the [] indicate an optional parameter.

Gets or sets the verbose option, which prints a message upon entry to each method, with parameters,
and prints the tree at the start of L</process_tree()>.

C<verbose> is a parameter to L</new()>.

=head1 FAQ

=head2 Can I process the tree myself?

Sure. Just call L</root()> - after L</run()> - to get the root of the tree, and process it any way
you wish.

See L</process_tree()> for sample code. More information is in the docs for L<Tree::DAG_Node>
especially under the discussion of C<walk_down()>.

=head2 What are the attributes of the tree nodes?

Firslty, each node has a name, which you can set or get with the C<name([$new_name])> method. Here,
[] refer to an optional parameter.

Secondly, the attributes of each node are held in a hashref, accessible with the C<attributes()>
method. The returned hashref has these (key => value) pairs:

=over 4

=item o name => $string

This is a copy of the name of the node. It's here because L</process_tree()> changes the name of
some nodes as it walks the tree.

=item o type => $string

This is the C<reftype()> (from the module L</Scalar::Util>) of the value (see the C<value> key,
below), or one of various strings I use, and hence has values like:

=over 4

=item o ARRAY

The value is an arrayref.

=item o BLESS

The value is blessed into a class, who name is in the value.

=item o CODE

The value is a coderef.

=item o HASH

The value is a hashref.

=item o REF

The value is presumably a generic reference. I could not see an explanation which I skimmed the
output of 'perldoc perlref'.

=item o SCALAR

The value is a scalarref.

=item o VALUE

The value is just a literal value.

I did not use LITERAL because the 1-letter abbreviation 'L' clashes with the 1-letter abbreviation
of 'LVALUE', which C<reftype()> can return.

=back

Other values returned by C<reftype()> are not used by this module.

=item o uid => $integer

Each node in the tree has a unique integer identifier, counting from 1 up.

=item o use_value => $Boolean

Node values (see next point) can be undef, and this flag serves the following purpose:

=over

=item o Zero

Do not use the value. It's undef, and set by the code, and thus not a real node's value.

=item o One

The node's value really is undef, or any other value. Use it in the output.

=back

=item o value => $string

Finally, the actual value of the node.

=back

=head2 Why are there so many levels in the output?

Or: Couldn't you cut some cases showing '{}' and '[]'?

Cutting them introduces other problems, especially when the input is a set of nested arrayrefs.

See scripts/array.pl, example 4 (hash key 4), for such a case.

=head2 Why do you decorate the output with e.g. [HASH 1] and not [H1]?

I feel the style [H1] used by L<Data::TreeDumper> is unnecessarily cryptic.

=head2 Why did you use Text::Truncate?

The major alternatives are L<String::Truncate> and L<Text::Elide>, or re-inventing the wheel.

The first module seems too complex, and the second truncates to whole words, which makes sense in
some applications, but not for dumping raw data.

=head2 How would I go about sub-classing this module?

This matter is discussed in the notes for method L</process_tree()>.

=head1 See Also

L<Data::TreeDumper>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Data-RenderAsTree>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data::RenderAsTree>.

=head1 Author

L<Data::RenderAsTree> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
