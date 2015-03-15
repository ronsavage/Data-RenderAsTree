#!/usr/bin/env perl

use strict;
use warnings;

use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------

my($count)  = 0;
my(%source) =
(
	1 =>
	{
		data     => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} }),
		expected => <<EOS
Bless Demo
    |--- Class = Tree::dag_node [Bless 1]
    |    |--- attributes = {} [Hash 2]
    |    |    |--- one = 1 [Value 3]
    |    |--- daughters [Array 4]
    |--- mother = undef [Value 5]
    |--- name = Root [Value 6]
EOS
	},
	2 =>
	{
		data     => {root => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })},
		expected => <<EOS
Bless Demo
    |--- root = {} [Hash 1]
    |--- Class = Tree::dag_node [Bless 2]
    |    |--- attributes = {} [Hash 3]
    |    |    |--- one = 1 [Value 4]
    |    |--- daughters [Array 5]
    |--- mother = undef [Value 6]
    |--- name = Root [Value 7]
EOS
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Bless Demo',
		verbose          => 0,
	);

my($expected);
my($got);

for my $i (sort keys %source)
{
	$got      = $renderer -> run($source{$i}{data});
	$expected = [split(/\n/, $source{$i}{expected})];

	is_deeply($got, $expected, 'Rendered'); $count++;
}

done_testing($count);
