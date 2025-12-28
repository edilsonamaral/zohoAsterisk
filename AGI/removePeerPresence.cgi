#!/usr/bin/perl

use strict;
use warnings;
use File::Copy qw(copy);
use 5.010;

die "Missing argument 1 company!" unless $ARGV[0];
die "Missing argument 2 extension!" unless $ARGV[1];
my $customer = $ARGV[0];
my $extension = $ARGV[1];
my $asteriskDir='/etc/asterisk/';
my $fileToModify="$asteriskDir"."$customer".'.ael';

local @ARGV = ($fileToModify);
local $^I = '.bac';

my $HINT_LINE_EXIST = 0;

if(-e $fileToModify){
	say "looking for file contanining $extension";
	# check if file contains string
	while(<>) {
        	if (/hint\(SIP\/$extension/) {
			$HINT_LINE_EXIST=1;
			#  HINT FOUND !!   remove it by not printing.
        	}else{
        		print;
		}
	}
}
else{
	say 'File not found';
}
say 'done';
