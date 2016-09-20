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
		print "ЋЎ­®ў«пҐ¬ $hostsPath...\n";

		if (scalar(keys %log)) {
			print "  ЋвЄ в ЇаҐ¤л¤гйЁе Ё§¬Ґ­Ґ­Ё©... ";
			my %del=deleteHosts($h,%log);
			writeHostsLog(); # зЁбвЁ¬ ¦га­ «
			print "®в¬Ґ­Ґ­® е®бв®ў: ".scalar(keys %del)."\n";
		}

		# Add hosts from /home.
		my %dom = VhostTemplate::getAllVHosts_forHosts($httpd_conf);
		my %added = insertHosts($h,%dom);
#		warn join(", ", keys %added);

		# Add really added hosts to log.
		writeHostsLog(%added);

		# Save hosts.
		writeBinFile($hostsPath,$h);

		print "  „®Ў ў«Ґ­® е®бв®ў: ".scalar(keys %added)."\n";
	},
	stop => sub {
		###
		### STOP.
		###
		print "‚®ббв ­ ў«Ёў Ґ¬ $hostsPath...\n";

		my %del=deleteHosts($h,%log);
		writeHostsLog(); # clear log

		# Save hosts.
		if(eval { writeBinFile($hostsPath,$h); 1 }) {
			print "  ѓ®в®ў®. ЋвЄ«озҐ­® е®бв®ў: ".scalar(keys %del)."\n";
		} else {
			print "  ЌҐ¤®бв в®з­® ЇаЁўЁ«ҐЈЁ©, Їа®ЇгйҐ­®.\n";
		}

	},
;

return 1 if caller;