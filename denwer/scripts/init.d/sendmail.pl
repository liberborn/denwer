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

package Starters::Sendmail;
BEGIN { unshift @INC, "../lib"; }

use Tools;
use Installer;
use ParseHosts;
use VhostTemplate;
use StartManager;

# Get common pathes.
my $basedir = '\\denwer\\tools\\sendmail';
my $startExe = 'sendmail_daemon_start.exe';
my $stopExe = 'sendmail_daemon_stop.exe';

chdir($basedir);

StartManager::action 
  $ARGV[0],
  start => sub {
    ###
    ### START.
    ###
    print "����᪠�� ����� ���⮢��� SMTP-�ࢥ�...\n";
    if (!-f $startExe) {
        die "  �� 㤠���� ���� $startExe.\n";
    } else {
        system("start $startExe");
        print "  ��⮢�.\n";
    }
  },
  stop => sub {
    ###
    ### STOP.
    ###
    print "�����蠥� ࠡ��� ����� ���⮢��� SMTP-�ࢥ�...\n";
    if (!-f $stopExe) {
        print "  �� 㤠���� ���� $stopExe.\n";
    } else {
        system("$stopExe");
        print "  ��⮢�.\n";
    }
  },
;


sub checkDaemonIfRunning {
}

return 1 if caller;
