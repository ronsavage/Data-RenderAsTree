#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise;
use Data::RenderAsTree;

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

my(%source) =
(
	1 =>
	{
		data     => \'s', # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS,
Ref Demo
    |--- SCALAR() [SCALAR 1]
EOS
		literal => q|\'s'|, # Use ' in comment for UltraEdit hiliting.
	},
	2 =>
	{
		data     => {key => \'s'}, # Use ' in comment for UltraEdit hiliting.
		expected => <<EOS,
Ref Demo
    |--- {} [HASH 1]
         |--- key = SCALAR() [SCALAR 2]
EOS
		literal => q|{key => \'s'}|, # Use ' in comment for UltraEdit hiliting.
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
my($i);

for $i (sort keys %source)
{
	$got      = [map{clean($_)} @{$renderer -> run($source{$i}{data})}];
	$expected = [map{clean($_)} split(/\n/, $source{$i}{expected})];

	print "$i: $source{$i}{literal}\n";
	print Dumper($got);
}