#!/usr/bin/perl -w

use 5.010;
use strict;
use warnings 'all';
use feature 'say';
use feature ':5.10';
use NetAddr::IP;

my $ip=$ARGV[0];
my $mask=$ARGV[1];
my $log=$ARGV[2];
say $ip;
say $mask;

my $cidr= make_cidr("$ip", "$mask");
system("/usr/sbin/iptables -I INPUT 3 -p udp --dport 5088 -s $cidr -m comment --comment '$log' -j voipattack");

sub make_cidr {
    my ($addr, $mask) = @_;
    my $net = NetAddr::IP->new($addr, $mask);
    $net->network;
}
