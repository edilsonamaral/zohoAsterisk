#!/usr/bin/perl -w

use strict;
#use Asterisk::AGI;

$|=1;

#my $AGI = new Asterisk::AGI;

my $phone=0; 
my $url=0; 
my $apikey=0; 
my $apisecret=0; 
my $result=0;
my $message="";
my $fromNumber="";

while(<STDIN>) {
    chomp;
    last unless length($_);
}

if ($ARGV[0]) {
    $phone = &URLEncode($ARGV[0]);
} else {
    # &setvar("OPENCNAM", "No Phone");
    # &setvar("CALLERID(name)", "Unknown");
    # &printverbose("OPENCNAM: No CALLFROM received.",2);
    exit(0);
}

$message=$ARGV[1];
#Get the sid
#  BULKVS.COM
#  $apikey = "94a8095715fc3fa84663b9bb5651d0ef";
#  $apisecret = "99a4e219f646d0c031da25d56c2ab4d8";
#  $url = "https://portal.bulkvs.com/sendSMS";

$apikey = "3umyw70l";
$apisecret = "47af8c75e60b661edddd4e6134920330";
$fromNumber = "14072050404";
$url = "https://api.apidaze.io/$apikey/sms/send?api_secret=$apisecret";

print "Send SMS\n";
print $phone."\n";
# $result = qx(curl -m 2 --connect-timeout 2  --speed-time 15 --speed-limit 5000 --header "Content-Type: application/json" -d '{"apikey":"$apikey","apisecret":"$apisecret","from":"14072702020","to":"$phone","message":"$message"}' -X POST $url);
$result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "from=$fromNumber" --data-urlencode "to=$phone" --data-urlencode "body=$message" -X POST $url);

print $result;

print "SMS -----";
eval {
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
        alarm 5;
        $result = qx(curl -m 2 -s "$url");
	alarm 0;
};
if ($@) {
        die unless $@ eq "alarm\n";   # propagate unexpected errors
        # timed out
}
else {
        # didn't
	if ($result) {
        	# $AGI->set_variable("AGI_SMS_RESULT", "$result");
	} else {
    		# &setvar("SENDSMS", "FAIL");
    		# &printverbose("SENDSMS: Timeout or error",2);
	}
}
# $result = qx(curl -m 2 -s "$url");
print "SMS ----2";
sub URLEncode {
   my $theURL = $_[0];
   $theURL =~ s/([W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
   return $theURL;
}

sub setvar {
    my ($var, $val) = @_;
    print STDOUT "SET VARIABLE $var '$val' n";
    while(<STDIN>) {
        m/200 result=1/ && last;
    }
    return;
}

sub printverbose {
    my ($var, $val) = @_;
    print STDOUT "VERBOSE '$var' $val";
    while(<STDIN>) {
        m/200 result=1/ && last;
    }
    return;
}
