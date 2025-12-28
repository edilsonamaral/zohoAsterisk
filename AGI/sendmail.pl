#!/usr/bin/perl
use strict;
use warnings;
$|=1;

#   Create or update a symlink so msmtp acts as sendmail
#   sudo ln -sf /usr/bin/msmtp /usr/sbin/sendmail


# Parse AGI environment (handshake)
my %AGI;
while (<STDIN>) {
    chomp;
    last unless length($_);
    if (/^agi_(\w+)\:\s+(.*)$/) { $AGI{$1} = $2; }
}

# Helper to GET VARIABLE from Asterisk
sub getvar {
    my ($name) = @_;
    print "GET VARIABLE $name\n";
    my $res = <STDIN> // '';
    $res =~ /result=1 \((.*)\)/ ? $1 : '';
}

# Read channel vars set in AEL
my $message = getvar('EMAIL_MSG');
my $subject = getvar('EMAIL_SUBJECT');
my $to      = getvar('EMAIL_TO');

# Guardrails
$subject =~ s/[\r\n]+/ /g;          # keep subject single-line
$message = '(empty)' unless length $message;
$to      = ''       unless length $to;

# Fail fast if TO missing
if ($to !~ /\@/ ) {
    print "VERBOSE \"Missing or invalid EMAIL_TO: [$to]\" 1\n";
    exit 1;
}

# Use msmtp; ensure asterisk can read /etc/msmtprc and write /var/log/msmtp.log
open(my $MAIL, "|/usr/bin/msmtp -t") or do {
    print "VERBOSE \"Failed to open msmtp\" 1\n";
    exit 1;
};

print $MAIL "To: $to\n";
# print $MAIL "From: donotreply\@evolvetelecom.net\n";
print $MAIL "Subject: $subject\n";
print $MAIL "Content-Type: text/plain; charset=UTF-8\n";
print $MAIL "Content-Transfer-Encoding: 8bit\n\n";
print $MAIL "$message\n";
close($MAIL);

print "VERBOSE \"Email queued to $to, subject: [$subject]\" 1\n";
exit 0;
