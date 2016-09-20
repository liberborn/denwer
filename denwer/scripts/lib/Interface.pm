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

package Interface;
$VERSION = 3.00;
use Tools;

# Экспортирует все функции в вызвавший пакет. Вызывается автоматически.
sub import {
	while(my ($k,$v)=each(%{__PACKAGE__."::"})) { 
		next if substr($k,-1) eq ":" || grep { $k eq $_ } qw(BEGIN import);
		*{caller()."::".$k}=$v;
	}
}


# void setDebugMode($mode)
# Sets the debug mode to true or false.
my $debugMode = 0;
sub setDebugMode {
	($debugMode) = @_;
}


# void getDebugMessages($msgs)
# Returns all printed debug messages.
my @debugMessages = ();
sub getDebugMessages {
	return @debugMessages;
}


# string rectangle($text, $style=2, $width=auto, $lspace=0, $pad=1)
# |         +---------------+
# | $lspace |$pad $text $pad|
# |         +---------------+
#            \_____________/ 
#                $width
my $prevStyle = "";
sub rectangle
{	my ($text, $style, $width, $lspace, $pad) = @_;
	$text = clean($text);
	$style=2 if !defined $style;
	$width||=0;
	$lspace||=0;
	$pad=1 if !defined $pad;
	
	# Detect max line length.
	my $w = 0;
	foreach (split /\n/, $text) {
		$w = length($_) if length($_)>$w;
	}
	$w += $pad*2 + 2;
	$width=$w if $w>$width;

	# Line styles.
	my %styles= ( #01234567
		"0"   => [split //, "        "],
		"1"   => [split //, "│┌─┐│└─┘"],
		"2"   => [split //, "║╔═╗║╚═╝"],
		"msg" => [split //, "█......."],
		"try" => [split //, "▓......."],
		"fnd" => [split //, "*......."],
		"dbg" => [split //, "<......>"],
	);
	my @style = map { $_ eq "."? "" : $_ } @{$styles{$style}||$style{2}};
	my $out = "";

	# Draw.
	$lspace = " " x $lspace;

	$out.=$lspace . $style[1] . $style[2] x ($width-2) . $style[3] . "\n" if $style[1] ne "";
	foreach my $l (split /\n/, $text) {
		$l .= " " x ($width-2-$pad*2-length($l));
		$out .= $lspace . $style[0] . " " x $pad . $l . " " x $pad . $style[4] . "\n";
	}	
	$out.=$lspace . $style[5] . $style[6] x ($width-2) . $style[7] . "\n" if $style[5] ne "";

	$prevStyle = $style;
	return $out;
}


# void message($st)
# Prints a MESSAGE..
sub message($)
{	my ($txt) = @_;
	print "\n" if $prevStyle ne "";
	print rectangle($txt,"msg");
}


# void found($st)
# Prints a FOUND message.
sub found($)
{	my ($txt) = @_;
	print "\n" if $prevStyle ne "fnd" && $prevStyle ne "try";
	print rectangle($txt,"fnd");
}


# void try($st)
# Prints a TRY-FOUND message.
sub try($)
{	my ($txt) = @_;
	print "\n" if $prevStyle ne "try" && $prevStyle ne "";
	print rectangle($txt,"try",undef,undef,1);
}


# void error($st)
# Prints an ERROR message.
sub error($)
{	my ($txt) = @_;
	print "\n";
	print rectangle($txt, 2);
}


# void debug($st)
# Prints a debug message.
sub debug($)
{	my ($txt) = @_;
	push @debugMessages, [ time(), $txt ];
	return if !$debugMode;
	print "\n";
	print rectangle($txt, 'dbg');
}


# void initialMessage($st)
# Prints an initial installation messge.
sub initialMessage($)
{	my ($txt) = @_;
	print rectangle($txt, 1);
}


# string ask($msg, $callback)
# Asks user a question.
sub ask($&) 
{	my ($msg,$func) = @_;
	print "\n";
	print "> ".$msg." ";
	$prevStyle = "ask";
	return $func->($msg) || '';
}


# Выводит строку. Если ее длина >$l символов, выводит только ее хвост.
# Курсор переводится на начало строки.
sub printLong
{	my ($s,$l)=@_;
	$l=70 if !defined $l;
	$s="...".substr($s,-($l-3)) if length($s)>$l;
	$s.=" "x($l-length $s);
	print $s;
	print "\b"x(length $s);
}


# bool readYesNo()
# Запрашивает у пользователя ответ "да" или "нет". Возвращает
# истину, если пользователь ввел "да".
sub readYesNo {
	my $yn;
	while (1) {
		$yn = lc trim(scalar <STDIN>);
		if ($yn ne "y" && $yn ne "n" && $yn ne "да" && $yn ne "нет") {
			print "Введите \"y\" (Да) или \"n\" (Нет): ";
			next;
		}
		return $yn eq "y" || $yn eq "да" || 0;
	}
}

# string readChoise($propmt, $default, @choises)
# Asks user to choose an element from the list.
sub readChoise
{	my ($prom, $def, @ch)=@_;
	my $ch;
	while(1) {
		$ch = ask "$prom [$def]:", sub { lc trim(scalar <STDIN>) };
		$ch = $def if $ch eq ""; 
		if (!grep { $_ eq $ch } @ch) {
			print "Неверный выбор. ";
			next;
		}
		return $ch;
	}
	
}


# void waitEnter()
# Waits for Enter keypress.
sub waitEnter {
	print rectangle(qq{
		Для продолжения нажмите Enter.
	}, 1);
	$prevStyle = "";
	<STDIN>;
}


# Выводит строку. Если ее длина >$l символов, выводит только ее хвост.
# Курсор переводится на начало строкиm, как будто ничего не выводилось.
sub progress
{	my ($s, $l)=@_;
	$l = 70 if !defined $l;
	$s = "..." . substr($s, -($l-3)) if length($s)>$l;
	$s .= " " x ($l - length $s);
	print $s;
	print "\b" x (length $s);
}


# bool showHtml($fname, $text)
# Shows a HTML message in a new IE window.
# Returns false if the temporary file cannot be created.
sub showHtml {
	my ($fname, $html) = @_;
	my $tmpFile = getTempDir() . '/' . $fname . '.html';
	open(F, ">$tmpFile") or return 0;
	print F $html;
	close F;
	system("start iexplore \"$tmpFile\"");
	return 1;
}


# void showDebug()
# Saves a debug information.
sub showDebug {
	# Add some information to debug dump available later via getDebugMessages().
	getComOutput("ver");
	getComOutput("set");
	if (-f (my $f = "c:\\autoexec.bat")) {
		getComOutput("type $f");
	}
	if (-f (my $f = "c:\\config.sys")) {
		getComOutput("type $f");
	}

	my $text = "";
	foreach my $msg (getDebugMessages()) {
		$text .= "[" . scalar(localtime($msg->[0])) . "]\n";
		$text .= clean($msg->[1]) . "\n\n";
	}

	# Wrap with HTML.
	$text = qq{
		<html>
		<head>
			<title>Ошибка при установке Денвера</title>
			<meta http-equiv="Content-type" content="text/html; charset=windows-1251">
		</head>
		<body bgcolor="white">
			<img src="http://www.denwer.ru/logo.gif?error" style="float:left; margin-right: 1em">

			<p>Пожалуйста, свяжитесь с разработчиками и перешлите им отладочное сообщение,
			приведенное ниже. (Оно не содержит персональных данных, но, если вы сомневаетесь,
			можете его тщательно просмотреть.) Это позволит выяснить причины ошибки. Форум 
			разработчиков: 
			<a href="http://forum.dklab.ru/denwer/bugs/">http://forum.dklab.ru/denwer/bugs/</a>.
			Не забудьте вначале воспользоваться 
			<a href="http://forum.dklab.ru/search.html?search_cat=4">Поиском по форуму</a>!</p>
			
			<textarea style="width:100%; height:60%; clear:both">$text</textarea>
		</body>
		</html>
	};

	# IE is a Windows program, so convert all to windows encoding.
	$text = ConvertCyrString($text, 'd', 'w');
	if (!showHtml('DENWER_DEBUG', $text)) {
		message qq{
			Не удается создать временный файл; вывод отладочной информации пропущен.
		};
		return;
	}
}


# void showSuccess($id, $name, $msg)
# Shows an IE window with success message.
sub showSuccess {
	my ($id, $name, $msg) = @_;
	$text = qq{
		<html>
		<head>
			<title>$name установлен успешно!</title>
			<meta http-equiv="Content-type" content="text/html; charset=windows-1251">
		</head>
		<body bgcolor="white">
			<img src="http://www.denwer.ru/logo.gif?ok=$id" style="float:right; margin-right: 1em">

			<h1>$name успешно установлен</h1>
			$msg
			
			<p>Если по каким-то причинам Денвер не заработал, свяжитесь, пожалуйста, с разработчиками:
			<a href="http://forum.dklab.ru/denwer/bugs/">http://forum.dklab.ru/denwer/bugs/</a>. Прикрепите к сообщению
			следующую информацию:
			<ol>
			<li>При каких условиях проявился баг? Что вы сделали перед тем, как его зафиксировали?
			<li>Точную версию Вашей OS (можно получить по команде <b>winver</b>, запущенной в Командной строке).
			<li>Файл <tt>netstat.txt</tt>, получившийся в результате работы команды <b>netstat -nb > C:\\netstat.txt</b> 
			  (кстати, этот файл не содержит персональной информации или сведений, подрывающих безопасность системы, хотя на неискушенный взгляд он и может показаться подозрительным).
			<li>Значимые сообщения из конца файла <tt>/usr/local/apache/logs/error.log</tt>.
			</ol>

			<p>Спасибо за использование Денвера!</p>
		</body>
		</html>
	};

	# IE is a Windows program, so convert all to windows encoding.
	$text = ConvertCyrString($text, 'd', 'w');
	showHtml('DENWER_SUCCESS', $text);
}

return 1;
