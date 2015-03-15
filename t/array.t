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
    |--- 0 [] [Array 1]
         |--- 0 = a [Scalar 2]
EOS
	},
	2 =>
	{
		data     => ['a', 'b'],
		expected => <<EOS
Array Demo
    |--- 0 [] [Array 1]
         |--- 0 = a [Scalar 2]
         |--- 1 = b [Scalar 3]
EOS
	},
	3 =>
	{
		data     => ['a', 'b', ['c'] ],
		expected => <<EOS
Array Demo
    |--- 0 [] [Array 1]
         |--- 0 = a [Scalar 2]
         |--- 1 = b [Scalar 3]
         |--- 2 [] [Array 4]
              |--- 0 = c [Scalar 5]
EOS
	},
	4 =>
	{
		data     => ['a', 'b', ['c', 'd'], 'e', ['f', ['g', 'h', ['i'], 'j'], 'k', 'l'], 'm'],
		expected => <<EOS
Array Demo
    |--- 0 [] [Array 1]
         |--- 0 = a [Scalar 2]
         |--- 1 = b [Scalar 3]
         |--- 2 [] [Array 4]
         |    |--- 0 = c [Scalar 5]
         |    |--- 1 = d [Scalar 6]
         |--- 3 = e [Scalar 7]
         |--- 4 [] [Array 8]
         |    |--- 0 = f [Scalar 9]
         |    |--- 1 [] [Array 10]
         |    |    |--- 0 = g [Scalar 11]
         |    |    |--- 1 = h [Scalar 12]
         |    |    |--- 2 [] [Array 13]
         |    |    |    |--- 0 = i [Scalar 14]
         |    |    |--- 3 = j [Scalar 15]
         |    |--- 2 = k [Scalar 16]
         |    |--- 3 = l [Scalar 17]
         |--- 5 = m [Scalar 18]
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
