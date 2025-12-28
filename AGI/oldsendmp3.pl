#!/usr/bin/perl

use strict;
use warnings;

# 1. ensure "attachfmt=wav" and "format=wav|gsm"
# 2. Put the below script in: /<pathto>/asterisk/agi-bin/sendmp3.pl
# 3. chmod a+rx mp3vm.pl
# 4. modify mailcmd=perl /<pathto>/asterisk/agi-bin/sendmp3.pl
# 5. install lame if you don't already have it
# 6. check the path to perl, base64, dos2unix and lame and modify the script and mailcmd as needed. 
# (If you are getting 0kb files, your path to lame is likely wrong.)

# yum install dos2unix

# dnf install http://repo.okay.com.mx/centos/8/x86_64/release/lame-3.100-6.el8.x86_64.rpm
# dnf install lame
#  old  open(VOICEMAIL,"|/usr/sbin/sendmail -t");


# Variables
my $temp_email = "/tmp/email_$$.txt";
my $temp_debug = "/var/spool/asterisk/tmp/vmout.debug.$$.txt";
my $temp_mp3 = "/var/spool/asterisk/tmp/vmout.$$.mp3";

unless (open(VOICEMAIL,"|/usr/bin/msmtp --debug --read-envelope-from -t >> /var/log/msmtp.log 2>&1")) {

# sudo touch /var/log/msmtp.log
# sudo chown asterisk:asterisk /var/log/msmtp.log
# sudo chmod 600 /var/log/msmtp.log
# Make sure your msmtprc file has: logfile /var/log/msmtp.log
# Rotate log: 
#	/var/log/msmtp.log {
#	weekly
#	rotate 4
#	compress
#	missingok
#	notifempty}

  die "Cannot open msmtp: $!";
}
open(LAMEDEC,"|/usr/bin/dos2unix|/usr/bin/base64 -di|/usr/bin/lame --quiet --preset voice - /var/spool/asterisk/tmp/vmout.$$.mp3");
open(VM,">/var/spool/asterisk/tmp/vmout.debug.txt"); 

my $inaudio = 0;

loop: while(<>){
  if(/^\.$/){
	last loop;
  }
  if(/^Content-Type: audio\/x-wav/i){
    	$inaudio = 1;
  }
  if($inaudio){
    while(s/^(Content-.*)wav(.*)$/$1mp3$2/gi){}
    if(/^\n$/){
      iloop: while(<>){
        print LAMEDEC $_;
        if(/^\n$/){
          last iloop;
        }
      }
      close(LAMEDEC);
      print VOICEMAIL "\n";
      print VM "\n";
      open(B64,"/usr/bin/base64 /var/spool/asterisk/tmp/vmout.$$.mp3|");
      while(<B64>){
        print VOICEMAIL $_; 
	print VM $_;	
      }
      close(B64);
      print VOICEMAIL "\n";
      print VM "\n";
      $inaudio = 0;
    }
  }
  print VOICEMAIL $_;
  print VM $_;
}
print VOICEMAIL "\.";
print VM "\.";
close(VOICEMAIL);
close(VM);

#CLEAN UP THE TEMP FILES CREATED
#This has to be done in a separate cron type job
#because unlinking at the end of this script is too fast,
#the message has not even gotten piped to send mail yet
