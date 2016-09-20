#!/usr/bin/perl -w

##
## Path to result file.
## You may edit it if you want.
##
my $out = "../../../tmp/!sendmail.txt";


open(local *F, ">>$out") or die "Couldn't open \"$out\"\n";
my $cmd = "[".localtime()."] sendmail ".join(" ",@ARGV);
print F $cmd."\n";
print F ("-" x max(75,length($cmd)))."\n";

my $len = 0;
my $sn;
while(defined($s=<STDIN>)) { 
	last if $s=~/^\.[\r\n]*$/s;
	print F $s;
	$sn = $s=~/\n/s;
	$len = length($s) if length($s)>$len;
}
print F "\n" if !$sn;
print F ("=" x max(75,$len))."\n\n";

close(F);

sub max
{	my ($a,$b) = @_;
	return $a>$b? $a : $b;
}