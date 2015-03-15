#!/usr/bin/env perl

use strict;
use warnings;

#use Data::Dumper::Concise;
use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------

my($count) = 0;
my(%source) =
(
	1 =>
	{
		data     => undef,
		expected => <<EOS
Undef Demo
    |--- undef [VALUE 1]
EOS
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Undef Demo',
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
