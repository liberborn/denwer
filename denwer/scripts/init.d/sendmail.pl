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
    print "‡ ЇгбЄ Ґ¬ н¬г«пв®а Ї®зв®ў®Ј® SMTP-бҐаўҐа ...\n";
    if (!-f $startExe) {
        die "  ЌҐ г¤ Ґвбп ­ ©вЁ $startExe.\n";
    } else {
        system("start $startExe");
        print "  ѓ®в®ў®.\n";
    }
  },
  stop => sub {
    ###
    ### STOP.
    ###
    print "‡ ўҐаи Ґ¬ а Ў®вг н¬г«пв®а  Ї®зв®ў®Ј® SMTP-бҐаўҐа ...\n";
    if (!-f $stopExe) {
        print "  ЌҐ г¤ Ґвбп ­ ©вЁ $stopExe.\n";
    } else {
        system("$stopExe");
        print "  ѓ®в®ў®.\n";
    }
  },
;


sub checkDaemonIfRunning {
}

return 1 if caller;
