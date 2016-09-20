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

package ParseHosts;
$VERSION = 3.00;
use Tools;
use Installer;
use VhostTemplate;

# Файл со списком хостов, добавленных в прошлый раз.
my $HOSTS_LOG   = dirname(__FILE__)."/AddedHosts.txt";

# IP-адрес хостов по умолчанию
my $DEF_IP = $VhostTemplate::DEF_IP;

# Marker to disable some of hosts.
my $DISABLE_MARKER = "## Disabled by denwer: ";


# Экспортирует все функции в вызвавший пакет. Вызывается автоматически.
sub import {
	while(my ($k,$v)=each(%{__PACKAGE__."::"})) { 
		next if substr($k,-1) eq ":" || grep { $k eq $_ } qw(BEGIN import);
		*{caller()."::".$k}=$v;
	}
}


# hash parseHosts($fname)
# Читает файл hosts. Возвращает хэш с ключами - именами хостов 
# и значениями - их ip-адресами.
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
# Читает файл журнала хостов. На самом деле, формат журнала 
# идентичен формату файла hosts.
sub readHostsLog {	
	return parseHosts($HOSTS_LOG);
}

sub cmpHost { 
	return -1 if $a eq "localhost";
	return 1 if $b eq "localhost";
	return length($b) <=> length($a);
} 



# hash writeHostsLog(%dom)
# Записывает файл журнала хостов.
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
# Модифицируетс строку $hosts (это содержимое файла c:/windows/hosts)
# так, чтобы там были добавлены хосты %dom. Если один из хостов уже
# присутствует в $hosts (например, с другим ip-адресом), он не торогается.
# Возвращает хосты, которые были добавлены.
sub insertHosts
{	local (*hosts, %dom)=(\$_[0], @_[1..$#_]);
	my %added=();
	foreach my $h (sort cmpHost keys %dom) {
		my $ip=$dom{$h};
		# Работаем с доменным именем $h.
		# Сначала проверяем, есть ли уже этот домен в $hosts.
		next if $hosts=~m{^ 
			[ \t]*                      # НЕЛЬЗЯ использовать \s!
			\d+ (\.\d+)+                # IP-адрес
			[^\#\r\n]+                  # пробелы и не-комментарии
			(?<=\s) \Q$h\E (?=[#\s]|$)  # домен целиком
		}mix;
		# Если нет, добавляем его в конец.
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
# Модифицируетс строку $hosts (это содержимое файла c:/windows/hosts)
# так, чтобы там были удалены хосты %dom, но только в случае 
# совпадения ip-адресов. 
# Возвращает хосты, которые были удалены.
sub deleteHosts
{	local (*hosts, %dom)=(\$_[0], @_[1..$#_]);
	my %del=();
	foreach my $h (keys %dom) {
		my $ip=$dom{$h};
		# Удаляем запись об этом хосте.
		$hosts=~s{^
			(	[ \t]*             # начальные пробелы - \s НЕЛЬЗЯ!
				\Q$ip\E            # IP-адрес
				[^\#\r\n]*         # пробелы и не-комментарии
			)
			(?<=\s) \Q$h\E ([ \t\r]+|$) # имя, окруженное пробелами
		}{
			$del{$h}=$ip; 
			$1
		}gmixe;
	}
	# Теперь удаляем записи, выглядящие как 
	# "127.0.0.1    # пусто"
	$hosts=~s{^ [ \t]* \d+(\.\d+)* [ \t]* (\#.*)? \r? \n}{}sgmx;
	# Restore bach Vista's "::1 localhost" if it was commented later.
	$hosts=~s/^[ \t]*\Q$DISABLE_MARKER\E//mg;
	return %del;
}


# string getHostsPath()
# Возвращает путь к системному файлу hosts.
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
				“бв ­®ўЄ  Їа ў ­  § ЇЁбм ў д ©« $hostsPath...
				ќв® ­Ґ®Ўе®¤Ё¬® ¤«п а Ў®вл бЁбвҐ¬л ¬­®¦ҐбвўҐ­­ле ўЁавг «м­ле е®бв®ў.
			};
			if (!$batch && getComOutput('VER') =~ /\[\S+\s+[6-9]/) {
				# Show this only in Vista.
				error qq{
					‚Ќ€ЊЂЌ€…!
					
					‘Ґ©з б „Ґ­ўҐа Ї®Їлв Ґвбп Ё§¬Ґ­Ёвм Їа ў  ¤®бвгЇ  ¤«п д ©«  hosts в Є, 
					зв®Ўл Ё¬Ґ« бм ў®§¬®¦­®бвм ¤®Ў ў«пвм ў ­ҐЈ® ­®ўлҐ ўЁавг «м­лҐ е®бвл.
					
					‘ЁбвҐ¬  § Їа®бЁв г ў б Ї®¤вўҐа¦¤Ґ­ЁҐ ­  ўлЇ®«­Ґ­ЁҐ нв®© ®ЇҐа жЁЁ, 
					в.Є. д ©« hosts ў Windows Vista ®в­®бЁвбп Є а §ап¤г § йЁйҐ­­ле. 
					
					‚л ¤®«¦­л ®вўҐвЁвм гвўҐа¤ЁвҐ«м­® ­  § Їа®б ® а §аҐиҐ­ЁЁ ¤Ґ©бвўЁп, 
					зв®Ўл Їа®¤®«¦Ёвм а Ў®вг.
					
					Hosts - нв® ®Ўлз­л© вҐЄбв®ўл© д ©« ў д®а¬ вҐ "ip- ¤аҐб Ё¬п-е®бв ".
					…Ј® Ё§¬Ґ­Ґ­ЁҐ ­Ґ ¬®¦Ґв Ї®ўаҐ¤Ёвм бЁбвҐ¬Ґ ¤ ¦Ґ вҐ®аҐвЁзҐбЄЁ.
				};
				waitEnter();
			}
			system(getToolExePath('AllowToModifyVirtualHosts.exe'));
		}

		if (!open(local *F, ">>$hostsPath")) {
			error qq{
				ЋиЁЎЄ ! ЌҐ г¤ «®бм гбв ­®ўЁвм Їа ў  ­  § ЇЁбм. ‚®§¬®¦­лҐ ЇаЁзЁ­л:
				- ‚л ­Ґ ®Ў« ¤ ҐвҐ ЇаЁўЁ«ҐЈЁп¬Ё Ђ¤¬Ё­Ёбва в®а  ­  ¤ ­­®¬ Є®¬ЇмовҐаҐ.
				- ‚л Їлв ҐвҐбм § ЇгбвЁвм Ё­бв ««пв®а „Ґ­ўҐа  б бҐвҐў®Ј® ¤ЁбЄ .
				- „«п Windows Vista: ўл ­Ґ а §аҐиЁ«Ё бЁбвҐ¬Ґ § ЇгбвЁвм гвЁ«Ёвг, 
				  гбв ­ ў«Ёў ойго Їа ў  ­  § ЇЁбм ў д ©« hosts.
				- ” ©« ®вЄалв ў ¬®­®Ї®«м­®¬ аҐ¦Ё¬Ґ ¤агЈ®© Їа®Ја ¬¬®© Ё«Ё  ­вЁўЁагб®¬.
				Џ®Їа®Ўг©вҐ ЇҐаҐ§ Јаг§Ёвм Є®¬ЇмовҐа.
			};
			return 0;
		}
	}
	return 1;
}


return 1;