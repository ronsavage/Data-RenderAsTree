#!/usr/bin/env perl

use strict;
use warnings;

#use Data::Dumper::Concise;
use Data::RenderAsTree;

use Test::More;

# ------------------------------------------------
# Remove things from strings which are run-dependent,
# e.g. memory addresses.

sub clean
{
	my($s) = @_;
	$s     =~ s/\(.+?\)/\(\)/g;

	return $s;

} # End of clean.

# ------------------------------------------------

my($count)  = 0;
my(%source) =
(
	1 =>
	{
		data     => \'s', # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS
Ref Demo
    |--- SCALAR(0x2068448) [SCALAR 1]
EOS
	},
	2 =>
	{
		data     => {key => \'s'}, # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS
Ref Demo
    |--- key = SCALAR() [SCALAR 1]
EOS
	},
);
my($renderer) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 25,
		max_value_length => 20,
		title            => 'Ref Demo',
		verbose          => 0,
	);

my($expected);
my($got);

for my $i (sort keys %source)
{
	$got      = [map{clean($_)} @{$renderer -> run($source{$i}{data})}];
	$expected = [map{clean($_)} split(/\n/, $source{$i}{expected})];

	#diag "\n", Dumper($got), Dumper($expected);

	is_deeply($got, $expected, 'Rendered'); $count++;
}

done_testing($count);
