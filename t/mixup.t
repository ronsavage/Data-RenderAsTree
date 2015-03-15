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
		data     => [{a => 'b'}],
		expected => <<EOS
Mixup Demo
    |--- 0 [] [ARRAY 1]
         |--- a = b [VALUE 2]
EOS
	},
	2 =>
	{
		data     => [{a => 'b'}, {c => 'd'}],
		expected => <<EOS
Mixup Demo
    |--- 0 [] [ARRAY 1]
         |--- a = b [VALUE 2]
         |--- c = d [VALUE 3]
EOS
	},
	3 =>
	{
		data     => [{a => 'b'}, ['c' => 'd'] ],
		expected => <<EOS
Mixup Demo
    |--- 0 [] [ARRAY 1]
         |--- a = b [VALUE 2]
         |--- 1 [] [ARRAY 3]
              |--- 0 = c [SCALAR 4]
              |--- 1 = d [SCALAR 5]
EOS
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Mixup Demo',
		verbose          => 0,
	);

my($expected);
my($got);

for my $i (sort keys %source)
{
	$got      = $renderer -> run($source{$i}{data});
	$expected = [split(/\n/, $source{$i}{expected})];

	diag "\n", Dumper($got), Dumper($expected);

	is_deeply($got, $expected, 'Rendered'); $count++;
}

done_testing($count);
