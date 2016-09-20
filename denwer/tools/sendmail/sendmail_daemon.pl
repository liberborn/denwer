#!/usr/bin/perl -w
BEGIN { unshift @INC, "../../scripts/lib"; }
require "common.pm";
use Tools;

my $pidFile = "sendmail_daemon.pid";

debug("Denwer mail server emulator.");
debug("Stores all SMTP mails to localhost:25 to /tmp."); 
debug("");


if (@ARGV && $ARGV[0] eq "-f") {
	debug("Terminating the daemon...");
	do {
		-f $pidFile or error("Daemon is not running.");
		open(local *F, $pidFile) or error("Cannot open the PID file $pidFile: $!\n");
		my $pid = trim(<F>);
		$pid or error("PID file $pidFile is empty!");
		kill(9, $pid);
		sleep 1; # this sleep is for unlink the lock file
		debug("Terminated process $pid.");
	};
	my $err = @_;
	unlink $pidFile;
	die $err if $err;
	exit(0);
}


# Save our PID in the file.
# Only one instance is guaranted by EXE wrapper!
open(F, ">$pidFile") or error("Cannot create $pidFile: $!\n");
print F "$$\n";
close(F);


my $listenHost = "localhost";
my $listenPort = common::getDaemonPort();

socket(Server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or error("socket: $!");
setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or error("setsockopt: $!");
bind(Server, pack_sockaddr_in($listenPort, gethostbyname($listenHost))) or error("bind: $!");
listen(Server, 1024) or error("listen: $!");

debug("Listening for connections on $listenHost:$listenPort...");


my $paddr;
for (; $paddr = accept(Client, Server); close Client) {
	binmode Client;
	my ($port, $iaddr) = unpack_sockaddr_in($paddr);
	my $name = gethostbyaddr($iaddr, AF_INET);
	my $from = "$name [" . inet_ntoa($iaddr) . ":$port]";
	debug("connection from $from opened");
	putline(\*Client, "Denwer mail daemon emulator", 220);
	while (!eof Client) {
		my $cmd = uc getline(\*Client);
		if ($cmd =~ /^HELO/) {
			putline(\*Client, "HELO $listenHost");
		} elsif ($cmd =~ /^EHLO/) {
			putline(\*Client, "EHLO $listenHost");
		} elsif ($cmd =~ /^QUIT/) {
			putline(\*Client, "Connection closed", 221);
			last;
		} elsif ($cmd =~ /^$/) {
			putline(\*Client, "Unsupported command", 580);
		} elsif ($cmd eq 'DATA') {
			putline(\*Client, "Pass the mail body ended with \".\"", 354);
			my $data = '';
			while (!eof Client) {
				my $line = <Client>;
				last if $line =~ /^\.\s*$/s;
				$data .= $line;
			}
			debug("< (Received the mail body, " . length($data) . " bytes length)");
			putline(\*Client, "Message accepted");
			common::processReceivedMail(
				$data, 
				"X-Sendmail-Daemon-From: $from"
			);
		} else {
			putline(\*Client, "OK");
		}
	}
	debug("connection from $from closed");
}


sub debug {
	print STDERR "[" . scalar(localtime) . "] " . join("", @_) . "\n";
}


sub error {
	print STDERR "[" . scalar(localtime) . "] " . join("", @_) . "\n";
	exit(1);	
}


sub getline {
	my ($fh) = @_;
	my $cmd = <Client>;
	$cmd =~ s/\s+$//sg;
	debug("< $cmd");
	return $cmd;
}


sub putline {
	my ($fh, $line, $code) = @_;
	$code ||= 250;
	$line = $code . ' ' . $line;
	print $fh  "$line\r\n";
	flush($fh);
	debug("> $line");
}
