#!/usr/bin/perl
use strict;
use warnings;
use Math::BigInt;
use Time::HiRes qw(time);
use Asterisk::AGI;

# Configuration
use constant PAYLOAD_BYTES => 35;
use constant BASE62_CHARS  => 48;
my $BASE62 = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz';

# Read exactly $len random bytes using sysread reliably
sub rand_bytes {
    my ($len) = @_;
    $len ||= 16;
    open my $fh, '<', '/dev/urandom' or die "Can't open /dev/urandom:  $!\n";
    binmode $fh;
    my $buf = '';
    my $read_total = 0;
    while ($read_total < $len) {
        my $r = sysread($fh, my $chunk, $len - $read_total);
        die "sysread from /dev/urandom failed: $!\n" unless defined $r;
        last if $r == 0;
        $buf .= $chunk;
        $read_total += $r;
    }
    close $fh;
    die "Failed to read $len bytes from /dev/urandom (got $read_total)\n" unless $read_total == $len;
    return $buf;
}

# Convert PAYLOAD_BYTES -> base62 (48 chars)
sub bytes_to_base62 {
    my ($bytes) = @_;
    die "bytes must be exactly " . PAYLOAD_BYTES .  " bytes\n" unless defined $bytes && length($bytes) == PAYLOAD_BYTES;

    my $hex = unpack('H*', $bytes);                # hex string, big-endian
    # Build BigInt from hex
    my $n = Math::BigInt->new('0x' . $hex);

    my $base = length($BASE62);
    my $s = '';
    
    # Handle zero case
    if ($n->is_zero) {
        return (substr($BASE62, 0, 1) x BASE62_CHARS, $hex, '0x0');
    }
    
    while (!$n->is_zero) {
        my $r = $n->copy()->bmod($base)->numify();
        $s = substr($BASE62, $r, 1) . $s;
        $n->bdiv($base);
    }
    
    # Pad with leading zeros if needed
    if (length($s) < BASE62_CHARS) {
        $s = (substr($BASE62, 0, 1) x (BASE62_CHARS - length($s))) . $s;
    }
    
    return ($s, $hex, Math::BigInt->new('0x' . $hex)->as_hex);
}

# Convert base62 -> PAYLOAD_BYTES
sub base62_to_bytes {
    my ($s) = @_;
    return unless defined $s && length($s) == BASE62_CHARS;

    my $base = length($BASE62);
    my $n = Math::BigInt->new(0);
    foreach my $c (split //, $s) {
        my $i = index($BASE62, $c);
        return unless $i >= 0;
        $n->bmul($base)->badd($i);
    }

    my $hex = $n->as_hex; $hex =~ s/^0x//i;
    my $expected_hex_len = PAYLOAD_BYTES * 2;
    if (length($hex) < $expected_hex_len) {
        $hex = ('0' x ($expected_hex_len - length($hex))) . $hex;
    } elsif (length($hex) > $expected_hex_len) {
        $hex = substr($hex, -$expected_hex_len);
    }
    return pack('H*', $hex);
}

sub reversible_encode {
    my ($original, $debug) = @_;
    defined $original or die "original required";
    my $orig_bytes = $original;
    my $len = length($orig_bytes);
    die "original too long (max 16 bytes)" if $len > 16;

    my $padding_len = PAYLOAD_BYTES - 1 - $len;
    die "internal error: negative padding" if $padding_len < 0;

    my $payload = pack('C', $len) . $orig_bytes . ($padding_len ? rand_bytes($padding_len) : '');
    die "payload length wrong: " . length($payload) unless length($payload) == PAYLOAD_BYTES;

    my ($id, $hex, $big_hex) = bytes_to_base62($payload);

    if ($debug) {
        print "DEBUG payload_hex: $hex\n";
        print "DEBUG bigint_hex: $big_hex\n";
        print "DEBUG base62_len: " . length($id) . "\n";
        print "DEBUG base62: $id\n";
    }

    return $id;
}

sub reversible_decode {
    my ($id48) = @_;
    return undef unless defined $id48 && length($id48) == BASE62_CHARS;
    my $payload = base62_to_bytes($id48);
    return undef unless defined $payload && length($payload) == PAYLOAD_BYTES;
    my $len = unpack('C', substr($payload, 0, 1));
    return undef if $len > 16;
    return substr($payload, 1, $len);
}

# CLI debug mode
if (-t STDIN) {
    my $first = shift @ARGV // '';
    if ($first eq '--debug') {
        my $orig = shift @ARGV // '';
        if (!$orig) {
            print "Usage: $0 --debug <original-string>\n";
            exit 1;
        }
        my $id = reversible_encode($orig, 1);
        print "Original: '$orig'\nID (48 chars): $id\n";
        exit 0;
    }

    if ($first eq 'decode') {
        my $id = shift @ARGV // '';
        if (!$id) { print "Usage: $0 decode <48-char-id>\n"; exit 1; }
        my $orig = reversible_decode($id);
        print defined $orig ? "Decoded: '$orig'\n" : "Failed to decode\n";
        exit 0;
    }

    # normal encode
    my $orig = $first;
    if (!defined $orig || $orig eq '') { print "Usage: $0 <orig>\n"; exit 1; }
    my $id = reversible_encode($orig, 0);
    print "Original: '$orig'\nID (48 chars): $id\n";
    exit 0;
}

# AGI mode
my $AGI = Asterisk::AGI->new();
my $linkedId = $ARGV[0];
$linkedId = $AGI->get_variable('CHANNEL(linkedid)') unless defined $linkedId && length($linkedId);

if ($linkedId) {
    if (length($linkedId) > 16) {
        $AGI->verbose("ERROR: linkedId too long (len=" . length($linkedId) . ")", 1);
        my $fallback = reversible_encode(substr($linkedId,0,16));
        $AGI->set_variable('API_CALL_ID', $fallback);
        $AGI->set_variable('__API_CALL_ID', $fallback);
        $AGI->verbose("API_CALL_ID (fallback) set to: $fallback", 1);
    } else {
        my $apiCallId = reversible_encode($linkedId, 0);
        $AGI->set_variable('API_CALL_ID', $apiCallId);
        $AGI->set_variable('__API_CALL_ID', $apiCallId);
        $AGI->verbose("API_CALL_ID set to: $apiCallId (reversible)", 1);
    }
} else {
    $AGI->verbose("ERROR: No LinkedID provided", 1);
}

1;
