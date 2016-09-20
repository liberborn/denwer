#!perl -w
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
package Starters::Hosts;
BEGIN { unshift @INC, "../lib"; }

use Tools;
use Installer;
use ParseHosts;
use VhostTemplate;
use StartManager;

# Path to hosts file.
my $hostsPath=getHostsPath();

# Read hosts.
my $h=readBinFile($hostsPath);

# First delete hosts which was added before.
# We need it in case of doubled script running.
my %log=readHostsLog();

my $basedir     = $CNF{apache_dir};
my $httpd_conf  = "$basedir/conf/httpd.conf";

makeHostsWritable(1);

StartManager::action 
	$ARGV[0],
	PATH => [
	],
	start => sub {
		###
		### START.
		###
		print "������塞 $hostsPath...\n";

		if (scalar(keys %log)) {
			print "  �⪠� �।���� ���������... ";
			my %del=deleteHosts($h,%log);
			writeHostsLog(); # ��⨬ ��ୠ�
			print "�⬥���� ��⮢: ".scalar(keys %del)."\n";
		}

		# Add hosts from /home.
		my %dom = VhostTemplate::getAllVHosts_forHosts($httpd_conf);
		my %added = insertHosts($h,%dom);
#		warn join(", ", keys %added);

		# Add really added hosts to log.
		writeHostsLog(%added);

		# Save hosts.
		writeBinFile($hostsPath,$h);

		print "  ��������� ��⮢: ".scalar(keys %added)."\n";
	},
	stop => sub {
		###
		### STOP.
		###
		print "����⠭�������� $hostsPath...\n";

		my %del=deleteHosts($h,%log);
		writeHostsLog(); # clear log

		# Save hosts.
		if(eval { writeBinFile($hostsPath,$h); 1 }) {
			print "  ��⮢�. �⪫�祭� ��⮢: ".scalar(keys %del)."\n";
		} else {
			print "  �������筮 �ਢ������, �ய�饭�.\n";
		}

	},
;

return 1 if caller;