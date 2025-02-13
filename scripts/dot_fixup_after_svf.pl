#!/usr/bin/perl
use strict;
use warnings;

@ARGV or die "Usage: $0 file\n";

my $file = shift @ARGV;
open my $fh, '<', $file or die "Could not open '$file' for reading: $!\n";
my $s = do { local $/; <$fh> };
close $fh;

$s =~ s/label=".*fun: (.*)\\.*"/label="$1"/g;
while ($s =~ /(Node0x[0-9a-f]*) \[.*label="(.*)".*\]/g) {
    my $tag = $1;
    my $name = $2;
    $s =~ s/$tag/"$name"/g;
}

open $fh, '>', $file or die "Could not open '$file' for writing: $!\n";
print $fh $s;
close $fh;
