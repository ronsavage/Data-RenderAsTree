#!/usr/bin/env perl

use strict;
use warnings;

#use Data::Dumper::Concise;
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
    |--- Class = Tree::DAG_Node [BLESS 1]
    |    |--- attributes = {} [HASH 2]
    |    |    |--- one = 1 [VALUE 3]
    |    |--- daughters [ARRAY 4]
    |--- mother = undef [VALUE 5]
    |--- name = Root [VALUE 6]
EOS
	},
	2 =>
	{
		data     => {root => Tree::DAG_Node -> new({name => 'Root', attributes => {one => 1} })},
		expected => <<EOS
Bless Demo
    |--- root = {} [HASH 1]
         |--- Class = Tree::DAG_Node [BLESS 2]
         |    |--- attributes = {} [HASH 3]
         |    |    |--- one = 1 [VALUE 4]
         |    |--- daughters [ARRAY 5]
         |--- mother = undef [VALUE 6]
         |--- name = Root [VALUE 7]
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

	#diag "\n", Dumper($got), Dumper($expected);

	is_deeply($got, $expected, 'Rendered'); $count++;
}

done_testing($count);
