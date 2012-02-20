#!/usr/bin/perl -w
use strict;
use warnings;

sub bytes($) {
    use bytes;
    return length shift;
}
binmode(STDIN,  ":utf8")  || die "can't binmode STDIN";
binmode(STDOUT, ":utf8") || die "can't binmode STDOUT";

while (my $line = <STDIN>) {
    chomp ($line);
    print STDOUT $line," ", length $line,"\n";
}

close(STDIN)  || die "can't close STDIN: $!";
close(STDOUT) || die "can't close STDOUT: $!";
exit 0;
