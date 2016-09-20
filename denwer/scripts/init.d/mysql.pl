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

package Starters::Mysql;
BEGIN { unshift @INC, "../lib"; }

use Tools;
use Installer;
use StartManager;

# Seconds to wait mysql stop while restart is active.
my $timeout = 5;

# Base MySQL dir.
my $basedir = $CNF{mysql_dir};
die "  Could not find $basedir\n" if !-d $basedir;

# MySQL exe name.
my $exe = "$basedir\\bin\\$CNF{mysql_exe}";

# MySQL shutdown utility.

# Config.
my $config = fsgrep { /^my.(cnf|ini)$/i } $basedir;
die "  Could not find my.ini or my.cnf in $basedir\n" if !$config || !-f $config;

# MySQL port.
my $port = 3306;
my $conf = readBinFile($config) or die "  Could not read $config\n";
if ($conf =~ /^\s* port \s* = \s* (\d+)/mix) {
  $port = $1;
}


StartManager::action 
  $ARGV[0],
  PATH => [
  ],
  start => sub {
    ###
    ### START.
    ###
    print "����᪠�� MySQL...\n";

    if(chechSocketIfRunning($port)) {
      print "  MySQL 㦥 ����饭.\n";
    } else {
      if(!-f $exe) {
        print "  �� 㤠���� ���� $exe.\n";
      } else {
        # Run the server.
        my $cmd = join " ", (
          "start $exe",
          ($exe=~/mysqld-max/? ("--defaults-file=$config") : ()),
          "--user=root",
          "--standalone",
#          "--init-connect=\"insert into mysql.test set test=current_timestamp()\"",
          "--basedir=$basedir",
          "--character-sets-dir=$basedir/share/charsets",
          ($CNF{mysql_args}||""),
        );
        system $cmd;
        print "  ��⮢�.\n";
      }
    }

  },
  stop => sub {
    ###
    ### STOP.
    ###
    print "�����蠥� ࠡ��� MySQL...\n";

    my @ps = Tools::searchForProcesses($exe);
    if(@ps) {
      foreach my $ps (@ps) {
        my $r = kill 2, $ps->{pid};
      }
      sleep(1);
      # If some processes haven't finished, do it again
      # with more cruel signal.
      @ps = Tools::searchForProcesses($exe);
      foreach my $ps (@ps) {
        my $r = kill 9, $ps->{pid};
        print "  Process $ps->{exe} (PID=$ps->{pid}) killed with signal 9\n";
      }
      print "  ��⮢�.\n";
    } else {
      print "  MySQL �� ����饭.\n";
      system("taskkill /F /IM " . $CNF{mysql_exe});
    }
  },
  _middle => sub {
    ###
    ### MIDDLE: after "start" of "restart".
    ###
    my $tm = time();
    if(chechSocketIfRunning($port)) {
      print "������� �����襭�� MySQL (���ᨬ� $timeout ᥪ㭤) ";
      while(time() - $tm < $timeout) {
        print ". ";
        if(!chechSocketIfRunning($port)) {
          print "\n";
          return;
        }
        sleep(1);
      }
      print "\n";
      print "  �� 㤠���� ��������� �����襭��!\n";
    }

  },
;


return 1 if caller;