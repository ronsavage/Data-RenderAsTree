#!/usr/bin/env perl

use strict;
use warnings;

use Data::RenderAsTree;

use Tree::DAG_Node;

# ------------------------------------------------

my($s) =
{
	root => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} }),
};
my($result) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Bless Demo',
		verbose          => 1,
	) -> run($s, '');

print join("\n", @$result), "\n";
