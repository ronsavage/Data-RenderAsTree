#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurp; # For read_file().
use File::Spec;

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

my($count)     = 0;
my($file_name) = File::Spec -> catfile('t', 'expected.dat');
my(@expected)  = map{clean($_)} split(/\n/, read_file($file_name));
my($synopsis)  = File::Spec -> catfile('scripts', 'synopsis.pl');
my(@got)       = map{clean($_)} split(/\n/, `$^X -Ilib $synopsis`);

#diag "Got: " . join('', @got);
#diag "Exp: " . join('', @expected);

ok(join('', @got) eq join('', @expected), 'Processed t/expected.dat'); $count++;

done_testing($count);
