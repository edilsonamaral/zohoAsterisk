use strict;
use warnings;
use File::Copy qw(copy);
use 5.010;

die "Missing argument for company!" unless $ARGV[0];

my $customer = $ARGV[0];
my $asteriskDir='/etc/asterisk/';
my $newFilename="$asteriskDir"."$customer".'.ael';
my $extensionsFile = "$asteriskDir".'customers.ael';
my $template = "$asteriskDir".'evolve.ael';
my $newFile = "$asteriskDir"."$newFilename";
local @ARGV = ($extensionsFile);
local $^I = '.bac';

my $CUSTOMER_LINE_EXIST = 0;

sub createNewAEL {
        my ($name)=@_;
        $name=uc($name);  # uppercase
        unless (-e $newFilename){
                copy $template , $newFilename;
                say 'New file '."$newFilename".' created';
    		push @ARGV, $newFilename;
    		while(<>) {
                        if (m!ivr-EVOLVE!) {
				s/ivr-EVOLVE/ivr-$name/g;

                                # print "#include $newFilename\"\n";
                                # print "// *** END OF INCLUDES ***\n";
				print;
                        }
                        else {
                                print;
                        }
    		}
        }
}

# check if file contains string
while(<>) {
        if (m!$newFilename!) {
		$CUSTOMER_LINE_EXIST=1;
        }
        print;
}

unless ($CUSTOMER_LINE_EXIST) {
	# get file into memory again, it clears after first use
   	@ARGV = ($extensionsFile);
   	while(<>) {
        	if (m!^// \*\*\* END OF INCLUDES \*\*\*!) {
                	print "#include $newFilename\"\n";
                	print "// *** END OF INCLUDES ***\n";
        	}
        	else {
                	print;
        	}
   	}
	createNewAEL($customer);
}

say 'done';
