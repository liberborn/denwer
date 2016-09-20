@echo off
miniperl.exe -x %0
pause
exit
#!perl -w
#line 7

print "\nДолжны отображаться русские буквы.\n\n";

foreach (glob("*.exe"), glob("*.dll")) {
	local $/;
	open(local *F, $_) or die "Could not open $_: $!\n";
	my $line = <F>;
	$line =~ /MSVCRT.DLL/i or die "FATAL: $_ is not linked with standard MSVCRT.DLL!\n";
}
