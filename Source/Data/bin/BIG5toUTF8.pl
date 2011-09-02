#!/usr/bin/perl -w
use strict;
use warnings;
use Encode qw(decode FB_CROAK);

binmode(STDIN,  ":raw")  || die "can't binmode STDIN";
binmode(STDOUT, ":utf8") || die "can't binmode STDOUT";

while (my $line = <STDIN>) {
    eval { $line = decode("UTF-8", $line, FB_CROAK()) };
    if ($@) { 
        $line = decode("big5-hkscs", $line, 0); # silent
    }
    #$line =~ s/\R\z/\n/;  # fix raw mode reads
    print STDOUT $line;    
}

close(STDIN)  || die "can't close STDIN: $!";
close(STDOUT) || die "can't close STDOUT: $!";
exit 0;
