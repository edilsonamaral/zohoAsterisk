#!/usr/bin/perl

use strict;
use warnings;
use MIME::Base64;

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

# sudo touch /var/log/msmtp.log
# sudo chown asterisk:asterisk /var/log/msmtp.log
# sudo chmod 600 /var/log/msmtp.log
# sudo chmod 644 /etc/msmtprc
# Make sure your msmtprc file has: logfile /var/log/msmtp.log
# Rotate log: 
#	/var/log/msmtp.log {
#	weekly
#	rotate 4
#	compress
#	missingok
#	notifempty}

# Variables
my $temp_email = "/tmp/email_$$.txt";
my $temp_debug = "/var/spool/asterisk/tmp/vmout.debug.$$.txt";
my $temp_mp3   = "/var/spool/asterisk/tmp/vmout.$$.mp3";
my $msmtp_bin  = "/usr/bin/msmtp"; # adjust if needed

# Helper: Encode UTF-8 Subject if needed
sub encode_utf8_subject {
    my ($subject) = @_;
    if ($subject =~ /[^\x00-\x7F]/) {
        my $encoded = encode_base64($subject, "");
        return "=?UTF-8?B?$encoded?=";
    } else {
        return $subject;
    }
}

# Helper: Send email via msmtp safely
sub safe_msmtp_send {
    my ($email_file) = @_;
    my $cmd = "$msmtp_bin --debug --read-envelope-from -t < $email_file >> /var/log/msmtp.log 2>&1";
    my $exitcode = system($cmd);
    
    if ($exitcode != 0) {
        warn "⚠️ msmtp send failed with exit code $exitcode!";
        return 0;
    }
    return 1;
}

# Step 1: Build the email into a temp file
open(my $VOICEMAIL, ">", $temp_email) or die "Cannot open temp email file: $!";
# For Debugging -->   
open(my $VM, ">", $temp_debug) or die "Cannot open debug file: $!";
open(my $LAMEDEC, "|/usr/bin/dos2unix | /usr/bin/base64 -di | /usr/bin/lame --quiet --preset voice - $temp_mp3") 
    or die "Cannot open lame pipeline: $!";

my $inaudio = 0;

# Read the incoming email
loop: while (<>) {
    if (/^\.$/) {
        last loop;
    }

    if (/^Content-Type: audio\/x-wav/i) {
        $inaudio = 1;
    }

    if ($inaudio) {
        while (s/^(Content-.*)wav(.*)$/$1mp3$2/gi) {}
        if (/^\n$/) {
            iloop: while (<>) {
                print $LAMEDEC $_;
                if (/^\n$/) {
                    last iloop;
                }
            }
            close($LAMEDEC); # Finish MP3 encoding
            print $VOICEMAIL "\n";
            print $VM "\n";

            # Insert base64-encoded MP3
            open(my $B64, "-|", "/usr/bin/base64", $temp_mp3) or die "Cannot base64 mp3: $!";
            while (<$B64>) {
                print $VOICEMAIL $_;
                print $VM $_;
            }
            close($B64);

            print $VOICEMAIL "\n";
            print $VM "\n";
            $inaudio = 0;
            next;
        }
    }

    # Fix Subject header on the fly
    # 🛠️ Handle Subject cleanly
    if (/^Subject:\s*(.*)/i) {
        my $subject_line = $1;

        my $mailbox = "unknown";
        if ($subject_line =~ /mailbox\s+(\d+)/i) {
            $mailbox = $1;
        } else {
            warn "⚠️ Warning: could not extract mailbox from subject: [$subject_line]";
        }

#        my $subject_fixed = "📢 [Voicemail]: New message in mailbox $mailbox";
	my $subject_fixed = "📢 [Voicemail]: New message in mailbox";
        my $encoded_subject = encode_utf8_subject($subject_fixed);

        print $VOICEMAIL "Subject: $encoded_subject\n";
        print $VM "Subject: $encoded_subject\n";

        next; # 🛠️ Critical: Skip broken incoming Subject line
    }
    elsif (/^\s*$/) {
        # Insert UTF-8 headers at start of body
        print $VOICEMAIL "Content-Type: text/plain; charset=UTF-8\n";
        print $VOICEMAIL "Content-Transfer-Encoding: 8bit\n";
        print $VOICEMAIL "\n";
        print $VM "Content-Type: text/plain; charset=UTF-8\n";
        print $VM "Content-Transfer-Encoding: 8bit\n";
        print $VM "\n";
    }
    else {
        # Default: copy line
        print $VOICEMAIL $_;
        print $VM $_;
    }
}

# End of email
print $VOICEMAIL ".\n";
print $VM ".\n";

close($VOICEMAIL);
close($VM);

# Step 2: Send email safely
if (safe_msmtp_send($temp_email)) {
    # Optionally clean temp email file here if you want
    unlink $temp_email;
} else {
    warn "⚠️ Email sending failed. Leaving $temp_email for inspection.";
}




#CLEAN UP THE TEMP FILES CREATED
#This has to be done in a separate cron type job
#because unlinking at the end of this script is too fast,
#the message has not even gotten piped to send mail yet
