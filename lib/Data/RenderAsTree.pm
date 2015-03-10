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

has root =>
(
	default   => sub{return ''},
	is        => 'rw',
	isa       => Any,
	required => 0,
);

has stack =>
(
	default   => sub{return Set::Array -> new},
	is        => 'rw',
	isa       => Object,
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

	$attributes       = {} if (! $attributes);
	$$attributes{uid} = $self -> uid($self -> uid + 1);
	my($node)         = Tree::DAG_Node -> new({name => $name, attributes => $attributes});
	my($tos)          = $self -> stack -> length - 1;

	${$self -> stack}[$tos] -> add_daughter($node);

	return $node;

} # End of _add_daughter.

# ------------------------------------------------

sub _process_arrayref
{
	my($self, $parent, $value) = @_;
	my($index) = - 1;

	print "Entered _process_arrayref($parent, $value)\n" if ($self -> verbose);

	my($bless_type);
	my($ref_type);

	for my $item (@$value)
	{
		$bless_type = blessed $item;
		$ref_type   = reftype($item) || 'VALUE';

		if ($bless_type)
		{
			$self -> stack -> push($self -> _process_scalar($self -> _tos, "Class = $bless_type", 'BLESS') );
		}

		if ($ref_type eq 'ARRAY')
		{
			$self -> _process_arrayref($parent, $item);
		}
		elsif ($ref_type eq 'HASH')
		{
			$self -> _process_hashref($item);
		}
		elsif ($ref_type eq 'SCALAR')
		{
			$self -> _process_scalar($parent, $item);
		}
		else
		{
			# These are the scalar array elements.

			$index++;

			$self -> _process_scalar($parent, "$index = " . (defined($item) ? truncstr($item, $self -> max_value_length) : 'undef') );
		}

		$self -> stack -> pop if ($bless_type);
	}

} # End of _process_arrayref;

# ------------------------------------------------

sub _process_hashref
{
	my($self, $data) = @_;
	my($tos)  = $self -> stack -> length - 1;

	print "Entered _process_hashref($data)\n" if ($self -> verbose);

	my($bless_type);
	my($node);
	my($ref_type);
	my($value);

	for my $key (sort keys %$data)
	{
		$value      = $$data{$key};
		$bless_type = blessed $value;
		$ref_type   = reftype($value) || 'VALUE';
		$node       = $self -> _add_daughter
			(
				truncstr($key, $self -> max_key_length),
				{type => $ref_type, value => defined($value) ? $value : 'undef'}
			);

		if ($bless_type)
		{
			$self -> stack -> push($self -> _process_scalar($self -> _tos, "Class = $bless_type", 'BLESS') );
		}

		if ($ref_type eq 'ARRAY')
		{
			$self -> stack -> push($node);

			$self -> _process_arrayref($node, $value);

			$self -> stack -> pop;
		}
		elsif ($ref_type eq 'HASH')
		{
			$self -> stack -> push($node);

			$self -> _process_hashref($value);

			$self -> stack -> pop;
		}
		elsif ($ref_type eq 'REF')
		{
			$self -> _process_scalar($node, $value);
		}
		elsif ($ref_type eq 'SCALAR')
		{
			$self -> _process_scalar($node, $value);
		}

		$self -> stack -> pop if ($bless_type);
	}

} # End of _process_hashref.

# ------------------------------------------------

sub _process_scalar
{
	my($self, $parent, $value, $type) = @_;
	$type ||= 'SCALAR';

	print "Entered _process_scalar($parent, $value, $type)\n" if ($self -> verbose);

	$self -> stack -> push($parent);

	my($node) = $self -> _add_daughter
		(
			$value,
			{type => $type, value => '-'}
		);

	$self -> stack -> pop;

	return $node;

} # End of _process_scalar.

# ------------------------------------------------

sub process_tree
{
	my($self) = @_;

	if ($self -> verbose)
	{
		print "Entered process_tree(). Printing tree before walk_down ...\n" if ($self -> verbose);
		print join("\n", @{$self -> root -> tree2string({no_attributes => 0})}), "\n";
		print '-' x 50, "\n";
	}

	my($attributes);
	my($id);
	my($key);
	my($name);
	my($ref_type);
	my($type);
	my($uid);
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
			$ref_type       = ($type =~ /^(\w+)/) ? $1 : $type; # substr($type, 0, 1);
			$uid            = $$attributes{uid};
			$value          = $$attributes{value};
			$key            = "$ref_type $uid";

			if ($$opt{seen}{$value})
			{
				$id = ($ref_type eq 'SCALAR') ? $key : "$key -> $$opt{seen}{$value}";
			}
			elsif ($ref_type eq 'CODE')
			{
				$id   = $key;
				$name = "$name = $value";
			}
			elsif ($ref_type eq 'REF')
			{
				$id  = $$opt{seen}{$$value} ? "$key -> $$opt{seen}{$$value}" : $key;
			}
			elsif ($ref_type eq 'VALUE')
			{
				$id   = $key;
				$name = (defined($name) ? truncstr($name, $self -> max_key_length) : 'undef') . ' = ' . (defined($value) ? truncstr($value, $self -> max_value_length) : 'undef');
			}
			else
			{
				$id = $key;
			}

			$node -> name("$name [$id]");

			$$opt{seen}{$value} = $id if (! defined $$opt{seen}{$value});

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
	$self -> stack -> push($self -> root);

	my($bless_type) = blessed $s;
	my($ref_type)   = reftype $s;

	if ($bless_type)
	{
		$self -> stack -> push($self -> _process_scalar($self -> root, "Class = $bless_type", 'BLESS') );
	}

	if ($ref_type eq 'ARRAY')
	{
		$self -> _process_arrayref($self -> root, $s);
	}
	elsif ($ref_type eq 'HASH')
	{
		$self -> _process_hashref($s);
	}
	elsif ($ref_type eq 'REF')
	{
		$self -> _process_scalar($self -> root, $s);
	}
	elsif ($ref_type eq 'SCALAR')
	{
		$self -> _process_scalar($self -> root, $s);
	}
	else
	{
		die "Sorry, don't know how to process a ref of type '$ref_type'\n";
	}

	$self -> stack -> pop if ($bless_type);

	$self -> process_tree;

	return $self -> root -> tree2string({no_attributes => 1 - $self -> attributes});

} # End of run.

# ------------------------------------------------

sub _tos
{
	my($self) = @_;
	my($tos)  = $self -> stack -> length - 1;

	return ${$self -> stack}[$tos];

} # End of _tos.

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
		ARA => [qw(element_1 element_2 element_3)],
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
		S => \'s', # Use ' in comment.
	};
	my($result) = Data::RenderAsTree -> new
		(
			attributes       => 0,
			max_key_length   => 7,
			max_value_length => 9,
			title            => 'Synopsis',
		) -> run($s);

	print join("\n", @$result), "\n";

This is t/expected.dat, the output of scripts/synopsis.pl:

	Synopsis
	    |--- A [HASH 1]
	    |    |--- a [HASH 2]
	    |    |--- bbbbbb = CODE(0xee3390) [CODE 3]
	    |    |--- c123 [CODE 4 -> CODE 3]
	    |    |--- d [REF 5 -> CODE 3]
	    |         |--- REF(0xee3210) [SCALAR 6]
	    |--- ARA [ARRAY 7]
	    |    |--- 0 = element_1 [SCALAR 8]
	    |    |--- 1 = element_2 [SCALAR 9]
	    |    |--- 2 = element_3 [SCALAR 10]
	    |--- C [HASH 11]
	    |    |--- b [HASH 12]
	    |         |--- a [HASH 13]
	    |              |--- a [HASH 14]
	    |              |--- b = CODE(0x15a3068) [CODE 15]
	    |              |--- c = 429999... [VALUE 16]
	    |--- DDDD... = d [VALUE 17]
	    |--- S [SCALAR 18]
	         |--- SCALAR(0x15be938) [SCALAR 19]

=head1 Description

L<Data::RenderAsTree> provides a mechanism to display a Perl data structure.

The data supplied to L</run($s)> is stored in an object of type L<Tree::DAG_Node>.

C<run()> returns an arrayref by calling C<Tree::DAG_Node>'s C<tree2string()> method.

This means you can display as much or as little of the result as you wish.

Hash key lengths can be limited by L</max_key_length($int)>, and hash value lengths can be limited
by L</max_value_length($int)>.

For sub-classing, see L</process_tree()>.

The module serves as a simple replacement for L<Data::TreeDumper>, but without the huge set of
features.

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

Sure. Just call L</root()> - after L</run()> - to get the root of the tree, and process it any way you wish.

See L</process_tree()> for sample code.

=head2 Why do you decorate the output with e.g. [HASH 1] and not [H1]?

I feel the style [H1] used by L<Data::TreeDumper> is unnecessarily cryptic.

=head2 What did you use Text::Truncate?

The major alternatives are L<String::Truncate> and L<Text::Elide>.

The former seems too complex, and the latter truncates to whole words, which makes sense in some
applications, but not for dumping raw data.

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
