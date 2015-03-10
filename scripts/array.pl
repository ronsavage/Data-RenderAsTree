#!/usr/bin/env perl

use strict;
use warnings;

use Data::RenderAsTree;

# ------------------------------------------------

#my($s)      = ['a', ['b', 'c'], [d => {e => 'f', 'g' => ['h', ['i'], 'j']}, 'k'], 'l', 'm'];
my($s)      = ['a'];
my($result) = Data::RenderAsTree -> new
	(
		attributes       => 0,
		max_key_length   => 15,
		max_value_length => 10,
		title            => 'Array',
		verbose          => 1,
	) -> run($s);

print join("\n", @$result), "\n";
