#!perl -w
# +-------------------------------------------------------------------------+
# | Джентльменский набор Web-разработчика                                   |
# | Версия: Денвер-3 2013-06-02                                             |
# +-------------------------------------------------------------------------+
# | Copyright (C) 2001-2010 Дмитрий Котеров.                                |
# +-------------------------------------------------------------------------+
# | Данный файл является частью комплекса программ "Денвер-3". Вы не можете |
# | использовать  его в коммерческих  целях.  Никакие другие ограничения не |
# | накладываются.  Если вы хотите внести изменения в исходный код,  авторы |
# | будут рады получить от вас комментарии и замечания. Приятной работы!    |
# +-------------------------------------------------------------------------+
# | Домашняя страница: http://denwer.ru                                     |
# | Контакты: http://forum.dklab.ru/denwer                                  |
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
    print "‡ ЇгбЄ Ґ¬ MySQL...\n";

    if(chechSocketIfRunning($port)) {
      print "  MySQL г¦Ґ § ЇгйҐ­.\n";
    } else {
      if(!-f $exe) {
        print "  ЌҐ г¤ Ґвбп ­ ©вЁ $exe.\n";
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
        print "  ѓ®в®ў®.\n";
      }
    }

  },
  stop => sub {
    ###
    ### STOP.
    ###
    print "‡ ўҐаи Ґ¬ а Ў®вг MySQL...\n";

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
      print "  ѓ®в®ў®.\n";
    } else {
      print "  MySQL ­Ґ § ЇгйҐ­.\n";
      system("taskkill /F /IM " . $CNF{mysql_exe});
    }
  },
  _middle => sub {
    ###
    ### MIDDLE: after "start" of "restart".
    ###
    my $tm = time();
    if(chechSocketIfRunning($port)) {
      print "Ћ¦Ё¤ Ґ¬ § ўҐаиҐ­Ёп MySQL (¬ ЄбЁ¬г¬ $timeout бҐЄг­¤) ";
      while(time() - $tm < $timeout) {
        print ". ";
        if(!chechSocketIfRunning($port)) {
          print "\n";
          return;
        }
        sleep(1);
      }
      print "\n";
      print "  ЌҐ г¤ Ґвбп ¤®¦¤ вмбп § ўҐаиҐ­Ёп!\n";
    }

  },
;


return 1 if caller;