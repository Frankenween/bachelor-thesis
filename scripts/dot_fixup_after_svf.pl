#!/usr/bin/perl
use strict;
use warnings;

@ARGV or die "Usage: $0 file\n";

my $file = shift @ARGV;
my $out_file = shift @ARGV;
open my $fh, '<', $file or die "Could not open '$file' for reading: $!\n";
my $s = do { local $/; <$fh> };
close $fh;

$s =~ s/label=".*fun: (.*)\\.*"/label="$1"/g;

# Create id -> name mapping for fast change
my %id_mapping = ();
while ($s =~ /(Node0x[0-9a-f]*) \[.*label="(.*)".*\]/g) {
	$id_mapping{"$1"} = $2;
#	print "$1 -> $2\n";
}

open $fh, '>', $out_file or die "Could not open '$out_file' for writing: $!\n";

print $fh "digraph {\n";
while ($s =~ /(Node0x[0-9a-f]*).* -> (Node0x[0-9a-f]*)/g) {
    my $callsite = $id_mapping{"$1"};
    my $callee = $id_mapping{"$2"};
    print $fh "    \"$callsite\" -> \"$callee\"\n";
}
print $fh "}\n";
close $fh;
