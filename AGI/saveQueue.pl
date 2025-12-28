#!/usr/bin/perl -w

#	Run it in background
#	nohup perl /var/lib/asterisk/agi-bin/saveQueue.pl &
#	ps aux | grep perl

use strict;
#use Asterisk::AGI;
use warnings qw/ all FATAL /;
use EV;
use Asterisk::AMI;

$|=1;

#my $AGI = new Asterisk::AGI;

my $result=0;
my $callid=0;
my $url = "http://67.9.85.238:8080/wscall-1.0/execute?";
# "https://api.apidaze.io/$apikey/sms/send?api_secret=$apisecret";
my $astman = Asterisk::AMI->new(PeerAddr        =>        '127.0.0.1',
                                PeerPort        =>        '51389',
                                Username        =>        'queueuser',
                                Secret => '123!@#Do',
                                Events => 'on',
                                Handlers        => { 	
						#	default => \&do_event,
                                                     	Hangup => \&do_hangup,
							BridgeEnter => \&do_BridgeEnter,
							BridgeLeave => \&do_BridgeLeave,
							AgentConnect => \&do_AgentConnect,
							AgentComplete => \&do_AgentComplete,
							DialBegin => \&do_DialBegin
							});
							 
die "Unable to connect to asterisk" unless ($astman);
 
sub do_event {
        my ($asterisk, $event) = @_;
        print 'DEFAULT ! Event Type: ' . $event->{'Event'} . "\r\n";
}
 
sub do_hangup {
        my ($asterisk, $event) = @_;
        if ($event->{'AccountCode'} ne ''){
                if ($event->{'AccountCode'} eq 'LOWTAX'){
			# if(index($event->{'Cause-txt'}, "Normal") != -1 || index($event->{'Cause-txt'}, "User busy") != -1 || index($event->{'Cause-txt'}, "Bearer capability") != -1 || index($event->{'Cause-txt'}, "Success") != -1){
				my $UniqueID = $event->{'Uniqueid'};
				if($callid eq $UniqueID){
					$result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "callID=$UniqueID" --data-urlencode "phoneNumber=" --data-urlencode "ramal=" --data-urlencode "type=HANGUP" -X GET $url);
	        			print 'Hangup on account: ' . $event->{'AccountCode'} . ' Hungup because ' . $event->{'Cause-txt'} . ' ID: ' . $event->{'Uniqueid'} . "\r\n";
					print $callid . "\r\n";
				}else{
                                        $result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "callID=$UniqueID" --data-urlencode "phoneNumber=" --data-urlencode "ramal=" --data-urlencode "type=HANGUP" -X GET $url);
                                        print 'Hangup on account: ' . $event->{'AccountCode'} . ' Hungup because ' . $event->{'Cause-txt'} . ' ID: ' . $event->{'Uniqueid'} . "\r\n";
                                        print $callid . "\r\n";
				}
			#}
		}
	}
}

sub do_BridgeEnter {
        my ($asterisk, $event) = @_;
        if ($event->{'AccountCode'} ne ''){
                if ($event->{'AccountCode'} eq 'LOWTAX'){
        	#	print 'Bridge Enter account:  ' . $event->{'AccountCode'} . ' New AccountCode ' . $event->{'Exten'} . "\r\n";
		}
	}
}

sub do_BridgeLeave {
        my ($asterisk, $event) = @_;
        if ($event->{'AccountCode'} ne ''){
                if ($event->{'AccountCode'} eq 'LOWTAX'){
		 #       print 'Bridge leave account:  ' . $event->{'AccountCode'} . ' New AccountCode ' . $event->{'Exten'} . "\r\n";
		}
	}
}

sub do_DialBegin {
        my ($asterisk, $event) = @_;
	if ($event->{'AccountCode'} ne ''){
		my $accountcode=$event->{'AccountCode'};
                if ($accountcode eq 'LOWTAX'){
			$callid = $event->{'Uniqueid'};
                        my $callerID = $event->{'CallerIDNum'};
                        my $UniqueID = $event->{'Uniqueid'};
			my $Dest = $event->{'Exten'};
			my $channel = $event->{'Channel'};
			if(index($event->{'Channel'},$event->{'AccountCode'}) != -1){
				my $stringToRemove = 'SIP/' . $accountcode;
				if(index($event->{'Channel'},'SIP') != -1){
					$stringToRemove = 'SIP/' . $accountcode;
        	                        $channel =~ s/$stringToRemove//;
	                                $channel =~ s/\-.*//;   # remove all strings afer "-"
				}elsif(index($event->{'Channel'},'Local') != -1){
					$stringToRemove = 'Local/';
                                        $channel =~ s/$stringToRemove//;
                                        $channel =~ s/\@.*//;   # remove all strings afer "@"
				}
				my $extension = $channel;
				print 'Extension:' . $extension . "\r\n";
				my $result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "callID=$UniqueID" --data-urlencode "phoneNumber=$Dest" --data-urlencode "ramal=$extension" --data-urlencode "type=DIAL" -X GET $url);
				print "$result" . "\r\n";
				print 'Dial begin ' . $event->{'AccountCode'} . ' DestExten:' . $event->{'DestExten'} . ' DestCallerIDNum:' . $event->{'DestCallerIDNum'} . ' Exten:' . $event->{'Exten'} . ' Dest number: ' . $event->{'DestConnectedLineNum'} . ' Channel ' . $event->{'Channel'} . ' ID: ' . $event->{'Uniqueid'} . "\r\n";
			}
                }
	}
}

sub do_AgentConnect {
        my ($asterisk, $event) = @_;
        if ($event->{'AccountCode'} ne ''){
                if ($event->{'AccountCode'} eq 'LOWTAX'){
			$callid = $event->{'Uniqueid'};
			# if($callid eq $event->{'Uniqueid'}){
                        	print 'CONNECT Agent: ' . $event->{'MemberName'} . ' AccountCode Hold time: ' . $event->{'HoldTime'} . 's ID: ' . $event->{'Uniqueid'} . ' From: ' . $event->{'CallerIDNum'} . "\r\n";
                        	my $callerID = $event->{'CallerIDNum'};
                        	my $UniqueID = $event->{'Uniqueid'};
                        	my $extension = $event->{'MemberName'};
				print 'Extension:' . $extension . "\r\n";
                        	$result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "callID=$UniqueID" --data-urlencode "phoneNumber=$callerID" --data-urlencode "ramal=$extension" --data-urlencode "type=ANSWER" -X GET $url);
				print "$result";
			# }
                }
        }
}

sub do_AgentComplete {
        my ($asterisk, $event) = @_;
        if ($event->{'AccountCode'} ne ''){
                if ($event->{'AccountCode'} eq 'LOWTAX'){
                        if($callid eq $event->{'Uniqueid'}){
                                print 'DISCONNECT  Agent Complete: ' . $event->{'MemberName'} .  ' AccountCode ' . $event->{'AccountCode'} . ' FROM: ' . $event->{'CallerIDNum'} . ' ID: ' . $event->{'Uniqueid'} . "\r\n";
                                my $callerID = $event->{'CallerIDNum'};
                                my $UniqueID = $event->{'Uniqueid'};
                                my $extension = $event->{'MemberName'};
                                $result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "callID=$UniqueID" --data-urlencode "phoneNumber=$callerID" --data-urlencode "ramal=$extension" --data-urlencode "type=HANGUP" -X GET $url);
                                print $event->{'DestCallerIDNum'};
                                print "$result";
                        }
                }
        }
}








#  $result = qx(curl -m 2 --connect-timeout 2 --speed-time 15 --speed-limit 5000 --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "from=$fromNumber" --data-urlencode "to=$phone" --data-urlencode "body=$message" -X POST $url);

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

#Start our loop
EV::loop
