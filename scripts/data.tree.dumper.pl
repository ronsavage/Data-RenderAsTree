#!/usr/bin/env perl

use strict;
use warnings;

use Data::TreeDumper; # For DumpTree().

# ------------------------------------------------

my($s)      = ['a', ['b', 'c'], [d => {e => 'f', g => ['h', ['i'], 'j']}, 'k'], 'l', 'm'];
#my($s)      = ['a'];

print DumpTree($s, 'Array Demo');
