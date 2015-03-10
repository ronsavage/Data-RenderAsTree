#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().
use Data::RenderAsTree;

use Scalar::Util qw/blessed reftype/;

use Tree::DAG_Node;

# ------------------------------------------------

my($s)      = Tree::DAG_Node -> new({name => 'Parent', attributes => {one => 1} });
my($result) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 55,
		max_value_length => 66,
		title            => 'Synopsis',
		verbose          => 0,
	) -> run($s);

print join("\n", @$result), "\n";
