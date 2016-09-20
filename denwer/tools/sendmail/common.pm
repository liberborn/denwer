package common;

#
# Path to the result directory.
#
my $out = "../../../tmp/!sendmail";

#
# Daemon port.
#
my $port = 25;


# Returns the daemon port number.
sub getDaemonPort {
	return $port;
}


# Generates the next mail filename.
sub generateFname {
	mkPath($out) or die "Could not create the directory structure $out\n";

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $fn0 = "$out/".sprintf("%.4d-%.2d-%.2d_%.2d-%.2d-%.2d.eml", $year+1900, $mon+1, $mday, $hour, $min, $sec);
	my $fn = $fn0;
	my $i = 1;
	while (-e $fn) {
		$fn = $fn0;
		$fn =~ s/(\.[^.]+)$/"_".($i++).$1/sge;
	}
	return $fn;	
} 


# Creates the specified directory path.
sub mkPath {
	my ($dir) = @_;
	my @parts = split m{[/\\]}, $dir;
	my $path = ".";
	foreach (@parts) {
		$path = "" if $_ eq "";
		$path .= ($path=~m{/$}? $_ : "/$_");
		if (!-e $path) {
			mkdir $path, 0770 or return;
		}
	}
	return 1;
}


# Saves the received mail.
sub processReceivedMail {
	my ($mail, $x) = @_;
	my $fn = generateFname();
	open(local *F, ">$fn") or die "Couldn't create \"$fn\"\n";
	binmode F;
	print F "$x\r\n" if $x;
	print F $mail;
}


return 1;
