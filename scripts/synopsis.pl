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
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Synopsis',
		verbose          => 0,
	) -> run($s);

print join("\n", @$result), "\n";
