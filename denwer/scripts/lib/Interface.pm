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

package Interface;
$VERSION = 3.00;
use Tools;

# ��ᯮ����� �� �㭪樨 � �맢��訩 �����. ��뢠���� ��⮬���᪨.
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
		"1"   => [split //, "��Ŀ����"],
		"2"   => [split //, "��ͻ��ͼ"],
		"msg" => [split //, "�......."],
		"try" => [split //, "�......."],
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


# �뢮��� ��ப�. �᫨ �� ����� >$l ᨬ�����, �뢮��� ⮫쪮 �� 墮��.
# ����� ��ॢ������ �� ��砫� ��ப�.
sub printLong
{	my ($s,$l)=@_;
	$l=70 if !defined $l;
	$s="...".substr($s,-($l-3)) if length($s)>$l;
	$s.=" "x($l-length $s);
	print $s;
	print "\b"x(length $s);
}


# bool readYesNo()
# ����訢��� � ���짮��⥫� �⢥� "��" ��� "���". �����頥�
# ��⨭�, �᫨ ���짮��⥫� ���� "��".
sub readYesNo {
	my $yn;
	while (1) {
		$yn = lc trim(scalar <STDIN>);
		if ($yn ne "y" && $yn ne "n" && $yn ne "��" && $yn ne "���") {
			print "������ \"y\" (��) ��� \"n\" (���): ";
			next;
		}
		return $yn eq "y" || $yn eq "��" || 0;
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
			print "������ �롮�. ";
			next;
		}
		return $ch;
	}
	
}


# void waitEnter()
# Waits for Enter keypress.
sub waitEnter {
	print rectangle(qq{
		��� �த������� ������ Enter.
	}, 1);
	$prevStyle = "";
	<STDIN>;
}


# �뢮��� ��ப�. �᫨ �� ����� >$l ᨬ�����, �뢮��� ⮫쪮 �� 墮��.
# ����� ��ॢ������ �� ��砫� ��ப�m, ��� ��� ��祣� �� �뢮������.
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
			<title>�訡�� �� ��⠭���� ������</title>
			<meta http-equiv="Content-type" content="text/html; charset=windows-1251">
		</head>
		<body bgcolor="white">
			<img src="http://www.denwer.ru/logo.gif?error" style="float:left; margin-right: 1em">

			<p>��������, �令��� � ࠧࠡ��稪��� � ���諨� �� �⫠��筮� ᮮ�饭��,
			�ਢ������� ����. (��� �� ᮤ�ন� ���ᮭ����� ������, ��, �᫨ �� ᮬ��������,
			����� ��� ��⥫쭮 ��ᬮ����.) �� �������� ���᭨�� ��稭� �訡��. ���� 
			ࠧࠡ��稪��: 
			<a href="http://forum.dklab.ru/denwer/bugs/">http://forum.dklab.ru/denwer/bugs/</a>.
			�� ������ ���砫� ��ᯮ�짮������ 
			<a href="http://forum.dklab.ru/search.html?search_cat=4">���᪮� �� ����</a>!</p>
			
			<textarea style="width:100%; height:60%; clear:both">$text</textarea>
		</body>
		</html>
	};

	# IE is a Windows program, so convert all to windows encoding.
	$text = ConvertCyrString($text, 'd', 'w');
	if (!showHtml('DENWER_DEBUG', $text)) {
		message qq{
			�� 㤠���� ᮧ���� �६���� 䠩�; �뢮� �⫠��筮� ���ଠ樨 �ய�饭.
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
			<title>$name ��⠭����� �ᯥ譮!</title>
			<meta http-equiv="Content-type" content="text/html; charset=windows-1251">
		</head>
		<body bgcolor="white">
			<img src="http://www.denwer.ru/logo.gif?ok=$id" style="float:right; margin-right: 1em">

			<h1>$name �ᯥ譮 ��⠭�����</h1>
			$msg
			
			<p>�᫨ �� �����-� ��稭�� ������ �� ��ࠡ�⠫, �令���, ��������, � ࠧࠡ��稪���:
			<a href="http://forum.dklab.ru/denwer/bugs/">http://forum.dklab.ru/denwer/bugs/</a>. �ਪ९�� � ᮮ�饭��
			᫥������ ���ଠ��:
			<ol>
			<li>�� ����� �᫮���� ����� ���? �� �� ᤥ���� ��। ⥬, ��� ��� ��䨪�஢���?
			<li>����� ����� ��襩 OS (����� ������� �� ������� <b>winver</b>, ����饭��� � ��������� ��ப�).
			<li>���� <tt>netstat.txt</tt>, ����稢訩�� � १���� ࠡ��� ������� <b>netstat -nb > C:\\netstat.txt</b> 
			  (����, ��� 䠩� �� ᮤ�ন� ���ᮭ��쭮� ���ଠ樨 ��� ᢥ�����, ����뢠��� ������᭮��� ��⥬�, ��� �� �����襭�� ����� �� � ����� ���������� ������⥫��).
			<li>���稬� ᮮ�饭�� �� ���� 䠩�� <tt>/usr/local/apache/logs/error.log</tt>.
			</ol>

			<p>���ᨡ� �� �ᯮ�짮����� ������!</p>
		</body>
		</html>
	};

	# IE is a Windows program, so convert all to windows encoding.
	$text = ConvertCyrString($text, 'd', 'w');
	showHtml('DENWER_SUCCESS', $text);
}

return 1;
