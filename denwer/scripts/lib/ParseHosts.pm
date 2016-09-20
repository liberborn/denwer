# +-------------------------------------------------------------------------+
# | �������������� ����� Web-������������                                   |
# | ������: ������-3 2013-06-02                                             |
# +-------------------------------------------------------------------------+
# | Copyright (C) 2001-2010 ������� �������.                                |
# +-------------------------------------------------------------------------+
# | ������ ���� �������� ������ ��������� �������� "������-3". �� �� ������ |
# | ������������  ��� � ������������  �����.  ������� ������ ����������� �� |
# | �������������.  ���� �� ������ ������ ��������� � �������� ���,  ������ |
# | ����� ���� �������� �� ��� ����������� � ���������. �������� ������!    |
# +-------------------------------------------------------------------------+
# | �������� ��������: http://denwer.ru                                     |
# | ��������: http://forum.dklab.ru/denwer                                  |
# +-------------------------------------------------------------------------+

package ParseHosts;
$VERSION = 3.00;
use Tools;
use Installer;
use VhostTemplate;

# ���� �� ������� ������, ����������� � ������� ���.
my $HOSTS_LOG   = dirname(__FILE__)."/AddedHosts.txt";

# IP-����� ������ �� ���������
my $DEF_IP = $VhostTemplate::DEF_IP;

# Marker to disable some of hosts.
my $DISABLE_MARKER = "## Disabled by denwer: ";


# ������������ ��� ������� � ��������� �����. ���������� �������������.
sub import {
	while(my ($k,$v)=each(%{__PACKAGE__."::"})) { 
		next if substr($k,-1) eq ":" || grep { $k eq $_ } qw(BEGIN import);
		*{caller()."::".$k}=$v;
	}
}


# hash parseHosts($fname)
# ������ ���� hosts. ���������� ��� � ������� - ������� ������ 
# � ���������� - �� ip-��������.
sub parseHosts {	
	my ($fname)=@_;
	open(local *F, $fname) or return ();
	my %dom=();
	while(<F>) {
		s/#.*|^\s+|\s+$//sg; next if $_ eq "";
		my ($ip,$h)=split(/\s+/, $_, 2);
		if(!defined $h) { $h=$ip; $ip=$DEF_IP; }
		foreach (split /\s+/, $h) {
			$dom{$_}=$ip;
		}
	}
	return %dom;	
}



# hash readHostsLog()
# ������ ���� ������� ������. �� ����� ����, ������ ������� 
# ��������� ������� ����� hosts.
sub readHostsLog {	
	return parseHosts($HOSTS_LOG);
}

sub cmpHost { 
	return -1 if $a eq "localhost";
	return 1 if $b eq "localhost";
	return length($b) <=> length($a);
} 



# hash writeHostsLog(%dom)
# ���������� ���� ������� ������.
sub writeHostsLog {	
	my (%dom)=@_;
	if(!scalar(keys %dom)) {
		unlink $HOSTS_LOG;
		return 1;
	}
	open(local *F, ">$HOSTS_LOG") or die "Could not create $HOSTS_LOG\n";
	print F "# This file is created by hosts update system\n";
	print F "# Please DO NOT modify and DO NOT delete it!\n";
	print F "# Following hosts will be deleted from 'hosts' on cleanup.\n\n";
	my @list=();
	my $ml=0;
	foreach my $k (sort cmpHost keys %dom) {
		push @list, "$dom{$k}	$k";
		$ml=length($k) if length($k)>$ml;
	}
	print F join("\n", @list, "");
	return 1;
}


# hash insertHosts(out string $hosts, %dom)
# ������������� ������ $hosts (��� ���������� ����� c:/windows/hosts)
# ���, ����� ��� ���� ��������� ����� %dom. ���� ���� �� ������ ���
# ������������ � $hosts (��������, � ������ ip-�������), �� �� ����������.
# ���������� �����, ������� ���� ���������.
sub insertHosts
{	local (*hosts, %dom)=(\$_[0], @_[1..$#_]);
	my %added=();
	foreach my $h (sort cmpHost keys %dom) {
		my $ip=$dom{$h};
		# �������� � �������� ������ $h.
		# ������� ���������, ���� �� ��� ���� ����� � $hosts.
		next if $hosts=~m{^ 
			[ \t]*                      # ������ ������������ \s!
			\d+ (\.\d+)+                # IP-�����
			[^\#\r\n]+                  # ������� � ��-�����������
			(?<=\s) \Q$h\E (?=[#\s]|$)  # ����� �������
		}mix;
		# ���� ���, ��������� ��� � �����.
		$hosts=~s/\s*$//s;
		$hosts.="\r\n" if $hosts ne "";
		$hosts.="$ip	$h\r\n";
		$added{$h}=$ip;
	}
	# Remove Vista's "::1 localhost", because it conflicts with Denwer.
	$hosts=~s/^([ \t]* ::1 [ \t]* localhost)/$DISABLE_MARKER$1/mgx;
	return %added;
}


# hash deleteHosts(string $hosts, %dom)
# ������������� ������ $hosts (��� ���������� ����� c:/windows/hosts)
# ���, ����� ��� ���� ������� ����� %dom, �� ������ � ������ 
# ���������� ip-�������. 
# ���������� �����, ������� ���� �������.
sub deleteHosts
{	local (*hosts, %dom)=(\$_[0], @_[1..$#_]);
	my %del=();
	foreach my $h (keys %dom) {
		my $ip=$dom{$h};
		# ������� ������ �� ���� �����.
		$hosts=~s{^
			(	[ \t]*             # ��������� ������� - \s ������!
				\Q$ip\E            # IP-�����
				[^\#\r\n]*         # ������� � ��-�����������
			)
			(?<=\s) \Q$h\E ([ \t\r]+|$) # ���, ���������� ���������
		}{
			$del{$h}=$ip; 
			$1
		}gmixe;
	}
	# ������ ������� ������, ���������� ��� 
	# "127.0.0.1    # �����"
	$hosts=~s{^ [ \t]* \d+(\.\d+)* [ \t]* (\#.*)? \r? \n}{}sgmx;
	# Restore bach Vista's "::1 localhost" if it was commented later.
	$hosts=~s/^[ \t]*\Q$DISABLE_MARKER\E//mg;
	return %del;
}


# string getHostsPath()
# ���������� ���� � ���������� ����� hosts.
sub getHostsPath {
	my $path;
	if ($ENV{OS} && $ENV{OS}=~/NT|XP|2000|2003/) {
		$path = "system32/drivers/etc/hosts";
	} else {
		$path = "hosts";
	}
	my $windir = Installer::findWindows();
	return "$windir/$path";
}


# void makeHostsWritable(bool $batch = 0)
# Makes the hosts file writable if it is not yet.
# Used by hosts updater & Denwer installer.
sub makeHostsWritable {
	my ($batch) = @_;
	my $hostsPath = getHostsPath();
	chmod(0666, $hostsPath);

	# Check if we running under Administrator.
	if (!open(local *F, ">>$hostsPath")) {
		# Code for NT versions.
		if ($ENV{OS} =~ /NT/) {
			try qq{
				��⠭���� �ࠢ �� ������ � 䠩� $hostsPath...
				�� ����室��� ��� ࠡ��� ��⥬� ������⢥���� ����㠫��� ��⮢.
			};
			if (!$batch && getComOutput('VER') =~ /\[\S+\s+[6-9]/) {
				# Show this only in Vista.
				error qq{
					��������!
					
					����� ������ ����⠥��� �������� �ࠢ� ����㯠 ��� 䠩�� hosts ⠪, 
					�⮡� ������� ����������� ��������� � ���� ���� ����㠫�� ����.
					
					���⥬� ������ � ��� ���⢥ত���� �� �믮������ �⮩ ����樨, 
					�.�. 䠩� hosts � Windows Vista �⭮���� � ࠧ��� ���饭���. 
					
					�� ������ �⢥��� �⢥न⥫쭮 �� ����� � ࠧ�襭�� ����⢨�, 
					�⮡� �த������ ࠡ���.
					
					Hosts - �� ����� ⥪�⮢� 䠩� � �ଠ� "ip-���� ���-���".
					��� ��������� �� ����� ���।��� ��⥬� ���� ⥮���᪨.
				};
				waitEnter();
			}
			system(getToolExePath('AllowToModifyVirtualHosts.exe'));
		}

		if (!open(local *F, ">>$hostsPath")) {
			error qq{
				�訡��! �� 㤠���� ��⠭����� �ࠢ� �� ������. �������� ��稭�:
				- �� �� �������� �ਢ�����ﬨ ����������� �� ������ ��������.
				- �� ��⠥��� �������� ���⠫���� ������ � �⥢��� ��᪠.
				- ��� Windows Vista: �� �� ࠧ�訫� ��⥬� �������� �⨫���, 
				  ��⠭���������� �ࠢ� �� ������ � 䠩� hosts.
				- ���� ����� � �������쭮� ०��� ��㣮� �ணࠬ��� ��� ��⨢���ᮬ.
				���஡�� ��१���㧨�� ��������.
			};
			return 0;
		}
	}
	return 1;
}


return 1;