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
		data     => ['a'],
		expected => <<EOS
Array Demo
    |--- 0 [] [ARRAY 1]
         |--- 0 = a [SCALAR 2]
EOS
	},
	2 =>
	{
		data     => ['a', 'b'],
		expected => <<EOS
Array Demo
    |--- 0 [] [ARRAY 1]
         |--- 0 = a [SCALAR 2]
         |--- 1 = b [SCALAR 3]
EOS
	},
	3 =>
	{
		data     => ['a', 'b', ['c'] ],
		expected => <<EOS
Array Demo
    |--- 0 [] [ARRAY 1]
         |--- 0 = a [SCALAR 2]
         |--- 1 = b [SCALAR 3]
         |--- 2 [] [ARRAY 4]
              |--- 0 = c [SCALAR 5]
EOS
	},
	4 =>
	{
		data     => ['a', 'b', ['c', 'd'], 'e', ['f', ['g', 'h', ['i'], 'j'], 'k', 'l'], 'm'],
		expected => <<EOS
Array Demo
    |--- 0 [] [ARRAY 1]
         |--- 0 = a [SCALAR 2]
         |--- 1 = b [SCALAR 3]
         |--- 2 [] [ARRAY 4]
         |    |--- 0 = c [SCALAR 5]
         |    |--- 1 = d [SCALAR 6]
         |--- 3 = e [SCALAR 7]
         |--- 4 [] [ARRAY 8]
         |    |--- 0 = f [SCALAR 9]
         |    |--- 1 [] [ARRAY 10]
         |    |    |--- 0 = g [SCALAR 11]
         |    |    |--- 1 = h [SCALAR 12]
         |    |    |--- 2 [] [ARRAY 13]
         |    |    |    |--- 0 = i [SCALAR 14]
         |    |    |--- 3 = j [SCALAR 15]
         |    |--- 2 = k [SCALAR 16]
         |    |--- 3 = l [SCALAR 17]
         |--- 5 = m [SCALAR 18]
EOS
	},
	5 =>
	{
		data     => [ ['a'] ],
		expected => <<EOS
Array Demo
    |--- 0 [] [ARRAY 1]
         |--- 0 [] [ARRAY 2]
              |--- 0 = a [SCALAR 3]
EOS
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Array Demo',
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
