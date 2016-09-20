#!perl -w
# +-------------------------------------------------------------------------+
# | ─цхэЄы№ьхэёъшщ эрсюЁ Web-ЁрчЁрсюЄўшър                                   |
# | ┬хЁёш : ─хэтхЁ-3 2013-06-02                                             |
# +-------------------------------------------------------------------------+
# | Copyright (C) 2001-2010 ─ьшЄЁшщ ╩юЄхЁют.                                |
# +-------------------------------------------------------------------------+
# | ─рээ√щ Їрщы  ты хЄё  ўрёЄ№■ ъюьяыхъёр яЁюуЁрьь "─хэтхЁ-3". ┬√ эх ьюцхЄх |
# | шёяюы№чютрЄ№  хую т ъюььхЁўхёъшї  Ўхы ї.  ═шъръшх фЁєушх юуЁрэшўхэш  эх |
# | эръырф√тр■Єё .  ┼ёыш т√ їюЄшЄх тэхёЄш шчьхэхэш  т шёїюфэ√щ ъюф,  ртЄюЁ√ |
# | сєфєЄ Ёрф√ яюыєўшЄ№ юЄ трё ъюььхэЄрЁшш ш чрьхўрэш . ╧Ёш Єэющ ЁрсюЄ√!    |
# +-------------------------------------------------------------------------+
# | ─юьр°э   ёЄЁрэшЎр: http://denwer.ru                                     |
# | ╩юэЄръЄ√: http://forum.dklab.ru/denwer                                  |
# +-------------------------------------------------------------------------+

##
## ВНИМАНИЕ!!!
## НЕ ПЕРЕИМЕНОВЫВАЙТЕ ЭТОТ СКРИПТ В subst.pl!!!
## Иначе Win2000 дерется с именем: subst.exe и subst.pl.
##

package Starters::Vdisk;
BEGIN { unshift @INC, "../lib"; }

use Tools;
use Installer;
use StartManager;


my $subst_drive = Installer::getSubstDriveConfig();
my $scripts_dir = "\\denwer\\scripts";

# Check drive name.
if (!$subst_drive && !dirLikeRoot("/")) {
	out qq{
		┌────────────────────────────────────────────────────────────┐
		│ Разрушен файл конфигурации системы: не удается считать имя │
		│ виртуального диска. Переинсталлируйте комплекс.            │
		└────────────────────────────────────────────────────────────┘
	};
	waitEnter();
	exit(100);
}

return 1 if !$subst_drive;


StartManager::action 
	$ARGV[0],
	start => sub {
		###
		### START.
		###
		return if $CNF{subst_drive} !~ /^\w/s;
		print "Инициализация виртуального диска $subst_drive...\n"; 

		if (!-d "$subst_drive\\") {
			my $found = searchForRoot();
			system(my $cmd="subst $subst_drive \"$found\"");

			# Check for success.
			if (!dirLikeRoot("$subst_drive\\")) {
				out qq{
					  ВНИМАНИЕ!
					  По неизвестным причинам не удается подключить виртуальный диск.
					  Не сработала команда: $cmd.
					  Продолжение работы невозможно.			  
				};
				waitEnter();
				exit(10);		
			}
			print "  Процесс подключения окончен.\n";
		} else {

			# Disc is already created. Check if it looks like root.
			if (!dirLikeRoot("$subst_drive\\")) {
				out qq{
					  ВНИМАНИЕ!
					  Виртуальный (или невиртуальный) диск $subst_drive уже имеется 
					  в системе, и он не похож на корневой каталог серверов. 
					  Попробуйте отключить диск (если он сетевой), или исправьте 
					  концигурационный файл комплекса. 
					  Продолжение работы невозможно.
				};
				waitEnter();
				exit(11);	
			} else {
				print "  Диск уже подключен.\n";
			}
		}

		# Now change directory to new drive for other scripts.
		chdir($subst_drive);
		chdir($scripts_dir);
	},
	stop => sub {
		###
		### STOP.
		###
		return if $CNF{subst_drive} !~ /^\w/s;
		print "Отключение виртуального диска $subst_drive...\n";

		if (-d "$subst_drive\\") {
			if (!dirLikeRoot("$subst_drive\\")) {
				print "  Не похоже, что диск создан комплексом, пропускаем.\n";
			} else {
				my $dir = getMappedPath($subst_drive);
				chdir("$dir\\denwer") if $dir !~ /^\Q$subst_drive/;
				# Disconnect the disk off.
				system("subst $subst_drive /d");
				# Success?
				if(dirLikeRoot("$subst_drive\\")) {
					out qq{
					  Не удалось отключить диск. Это не ошибка, лишь предупреждение.
					  Такое часто бывает в системах Windows 9x из-за ошибки в subst.exe.
					  Вы можете попробовать вручную запустить следующий файл:
					  $dir\\denwer\\SwitchOff.exe
					  Иногда помогает. В любом случае, диск будет отключен после перезагрузки.
					};
				} else {
					print "  Процесс отключения окончен.\n";
				}
			}
		} else {
			print "  Диск уже отключен.\n";
		}
	},
;



# Searches for root directory below current (which contains etc, 
# usr & home). We use it to connect to virtual drive. Searching is 
# more flexible than static path.
sub searchForRoot {
	my $found=undef;
	# Go down to root.
	for(my $dir=getcwd(); $dir && $dir ne "."; $dir=dirname($dir)) {
		if(dirLikeRoot($dir)) {
			$found=$dir;
			last;
		}
		last if isRootDir($dir);
	}
	return $found || "..\\..\\..";
}

return 1 if caller;