#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings 'all';
use feature 'say';
use feature ':5.10';
use NetAddr::IP;

my $filename = 'report.txt';
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";

my $ip=$ARGV[0];
my $mask=$ARGV[1];
say $ip;
say $mask;

print $fh "$addr, $mask\n";

my $cidr= make_cidr("$ip", "$mask");

# system("/usr/sbin/iptables -I INPUT 2 -s $cidr -j DROP");

sub make_cidr {
    my ($addr, $mask) = @_;
    my $net = NetAddr::IP->new($addr, $mask);
print $fh "$addr, $mask\n";
close $fh;
    $net->network;
}
