#!/usr/bin/perl -w

##
## Path of result directory.
## You may edit it if you want.
##
my $out = "../../../tmp/!sendmail";

#
# Read the mail.
#
my @lines;
while (<STDIN>) { 
	last if /^\.[\r\n]*$/s;
	push @lines, $_;
}


#
# Save the mail.
#
mkPath($out) or die "Could not create the directory structure $out\n";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $fn0 = "$out/".sprintf("%.4d-%.2d-%.2d_%.2d-%.2d-%.2d.eml", $year+1900, $mon+1, $mday, $hour, $min, $sec);
my $fn = $fn0;
my $i = 1;
while (-e $fn) {
	$fn = $fn0;
	$fn =~ s/(\.[^.]+)$/"_".($i++).$1/sge;
}

open(local *F, ">$fn") or die "Couldn't create \"$fn\"\n";
print F "X-Sendmail-Cmdline: $0 ".join(" ", @ARGV)."\n";
print F @lines;
              


##
## Subroutines.
##

# Find maximum of two numbers.
sub max
{	my $max = $_[0];
	foreach (@_) { $max = $_ if $_>$max }
	return $max;
}

# Creates the specified directory path.
sub mkPath
{	my ($dir) = @_;
	my @parts = split m{[/\\]}, $dir;
	my $path = ".";
	foreach (@parts) {
		$path = "" if $_ eq "";
		$path .= ($path=~m{/$}? $_ : "/$_");
#		warn "$path\n";
		if (!-e $path) {
			mkdir $path, 0770 or return;
		}
	}
	return 1;
}
