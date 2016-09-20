#!/usr/bin/perl -w
require "common.pm";


#
# Read the mail.
#
binmode STDIN;
my @lines;
while (<STDIN>) { 
	last if /^\.[\r\n]*$/s;
	push @lines, $_;
}


#
# Save the mail.
#
common::processReceivedMail(
	join("", @lines), 
	"X-Sendmail-Cmdline: $0 ".join(" ", @ARGV)
);
