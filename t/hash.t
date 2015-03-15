#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise;
use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------

my($count)  = 0;
my(%source) =
(
	1 =>
	{
		data     => {a => 'b'},
		expected => <<EOS
Hash Demo
    |--- a = b [Value 1]
EOS
	},
	2 =>
	{
		data     => {a => 'b', c => 'd'},
		expected => <<EOS
Hash Demo
    |--- a = b [Value 1]
    |--- c = d [Value 2]
EOS
	},
	3 =>
	{
		data     => {a => 'b', c => 'd', e => {f => 'g', h => 'i'} },
		expected => <<EOS
Hash Demo
    |--- a = b [Value 1]
    |--- c = d [Value 2]
    |--- e = {} [Hash 3]
         |--- f = g [Value 4]
         |--- h = i [Value 5]
EOS
	},
	4 =>
	{
		data     => {a => {b => 'c'} },
		expected => <<EOS
Hash Demo
    |--- a = {} [Hash 1]
         |--- b = c [Value 2]
EOS
	},
	5 =>
	{
		data     => {a => {b => 'c'}, d => 'e'},
		expected => <<EOS
Hash Demo
    |--- a = {} [Hash 1]
    |    |--- b = c [Value 2]
    |--- d = e [Value 3]
EOS
	},
	6 =>
	{
		data     => {a => {b => {c => 'd'} } },
		expected => <<EOS
Hash Demo
    |--- a = {} [Hash 1]
         |--- b = {} [Hash 2]
              |--- c = d [Value 3]
EOS
	},
	7 =>
	{
		data     => {a => 'b', c => 'd', e => {f => 'g', h => 'i', j => {k => 'l', m => 'n'}, o => 'p'}, q => 'r'},
		expected => <<EOS
Hash Demo
    |--- a = b [Value 1]
    |--- c = d [Value 2]
    |--- e = {} [Hash 3]
    |    |--- f = g [Value 4]
    |    |--- h = i [Value 5]
    |    |--- j = {} [Hash 6]
    |    |    |--- k = l [Value 7]
    |    |    |--- m = n [Value 8]
    |    |--- o = p [Value 9]
    |--- q = r [Value 10]
EOS
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Hash Demo',
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
