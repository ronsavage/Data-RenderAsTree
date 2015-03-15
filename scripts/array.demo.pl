#!/usr/bin/env perl

use strict;
use warnings;

use Data::RenderAsTree;

# ------------------------------------------------

#my($s)       =   ['a'];
#my($literal) = q|['a']|;
#my($s)       =   ['a', 'b'];
#my($literal) = q|['a', 'b']|;
#my($s)       =   ['a', 'b', ['c'] ];
#my($literal) = q|['a', 'b', ['c'] ]|;
my($s)        =   ['a', 'b', ['c', 'd'], 'e', ['f', ['g', 'h', ['i'], 'j'], 'k', 'l'], 'm'];
my($literal)  = q|['a', 'b', ['c', 'd'], 'e', ['f', ['g', 'h', ['i'], 'j'], 'k', 'l'], 'm']|;

print "$literal\n";

my($result)   = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Array Demo',
		verbose          => 1,
	) -> run($s);

print "$literal\n";
print join("\n", @$result), "\n";
