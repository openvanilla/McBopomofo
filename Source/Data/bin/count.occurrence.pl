#!/usr/bin/env perl -w
use strict;
my $query=$ARGV[0];
my $size = 0;
while (<STDIN>) {
   $size++ while $_ =~ /$query/g;
}
print "$query	$size\n";
exit;
