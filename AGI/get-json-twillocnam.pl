#!/usr/bin/perl -w

use strict;
#use Data::Dumper;
#use JSON;
use Asterisk::AGI;
# use JSON::XS;
#use JSON::Parse 'parse_json';

$|=1;
my $callerid="Inside";

while(<STDIN>) {
    chomp;
    last unless length($_);
}

print "Edilson 1\n";
print "@ARGV\n";
print "Edilson 2\n";
# Use loop to combine all command line arguments into one variable
# my $json1 = '';
# foreach my $arg(@ARGV) {
  #$json1 .= $arg;
#}

#my @results = split /,/, $json1;
#for my $result (@results) {
#	my %name_parts = split /:/, $result;
#	foreach my $key (keys %name_parts){
#		print "The current index : $key\n";
#	}
#	last;
#}


my $AGI = new Asterisk::AGI;
$AGI->set_variable("AGI_OPENCNAME_RESULT", " 123");


exit 1;
