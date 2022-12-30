use strict;

open my $in, '<', shift or die "SYNOPSIS: $0 shipname.BIN\n";
my $name = read $in, unpack "A23x";
close $in;

print "name: $name\n";

