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

package Tools;
$VERSION = 3.00;

# Constants.
sub AF_INET()      { 2 }
sub PF_INET()      { 2 }
sub SOCK_STREAM()  { 1 }
sub SOL_SOCKET()   { 65535 }
sub SO_REUSEADDR() { 4 }
sub INADDR_ANY     { pack('cccc', 0) }
sub SOMAXCONN      { 2147483647 }
sub LOCK_EX        { 2 }
sub LOCK_NB        { 4 }


# Automatically exprts all the functions.
sub import {
  while(my ($k,$v)=each(%{__PACKAGE__."::"})) { 
    next if substr($k,-1) eq ":" || grep { $k eq $_ } qw(BEGIN import);
    *{caller()."::".$k}=$v;
  }
}


# string clean(string $s)
# Cleans the string from prepending tabs & trailing \n-s.
sub clean($)
{ my ($txt)=@_;
  $txt=~s/\r//sg;
  $txt=~s/^\t+//gm;
  $txt=~s/^\n//s;
  return $txt;
}


# void out($st)
# Prints the string with cleaning.
sub out($)
{ my ($txt)=@_;
  print clean($txt);
}


# string trim($st)
sub trim($)
{ my ($s)=@_;
  $s=~s/^\s+//sg;
  $s=~s/\s+$//sg;
  return $s;
}


# string dirname($path)
sub dirname($)
{ my ($s)=@_;
  return "/" if $s eq "/" || $s eq "\\";
  return $1 if $s=~m{^(\w:)[/\\]?$};
  return "." if $s!~m{[\\/]};
  $s=~s([/\\][^/\\]*$)();
  return $s ne ""?$s:"/";
}


# string basename($path)
sub basename($)
{ my ($s)=@_;
  $s=~s{^.*[/\\]}{}s;
  return $s;
}


# bool isRootDir($dir)
# Returns wheither directory $dir is root (/, \ or \w:).
sub isRootDir($)
{ my ($d)=@_;
  return $d=~m{^([/\\]|\w:[/\\]?)$}? 1: 0;
}


# void writeTextFile($fname, $data)
# Writes $data to the whole file $fname in text mode.
sub writeTextFile($$)
{ my ($fname,$st)=@_;
  open(local *F,">$fname") or die "Cannot write to file \"$fname\"!\n";
  print F $st;
}


# void readTextFile($fname)
# Reads all the contents of text file (no \r at all).
# Returns "" if there is no file.
sub readTextFile($)
{ my ($fname)=@_;
  local $/;
  open(local *F,"$fname") or return "";
  my $s = <F>;
  $s=~s/\r//sg;
  return $s;
}


# void writeBinFile($fname, $data)
# Writes $data to the whole file $fname in binary mode.
sub writeBinFile($$)
{ my ($fname,$st)=@_;
  open(local *F,">$fname") or die "Cannot write to file \"$fname\"!\n";
  binmode(F); print F $st;
}


# void readBinFile($fname)
# Reads all the contents of binary file.
# Returns "" if there is no file.
sub readBinFile($)
{ my ($fname)=@_;
  open(local *F,"$fname") or return "";
  binmode(F); local $/;
  my $data = <F>; 
  $data = "" if !defined $data; # for miniperl
  return $data;
}


# string normSlashes($s)
# Replaces / to \.
sub normSlashes($)
{ my ($s) = @_;
  $s =~ s{/}{\\}sg;
  return $s;
}


# string getTempDir()
# Returns the system temporary directory.
sub getTempDir {
  return $ENV{TEMP} || $ENV{TMP} || "c:";
}


# string getComOutput(sring $command)
# Returns the STDOUT of specified command.
{{{
my $cnt=0;
sub getComOutput
{ my ($com) = @_;
  my ($tmp) = getTempDir() . "\\" . substr(time(), -6) . ($cnt++ % 100) . ".tmp";
  my $svPath = $ENV{PATH};
  # Stupid system() uses "command.com" instead of COMSPEC. Try to workaround it.
  $ENV{PATH} .= ";" . dirname($ENV{COMSPEC}) if $ENV{COMSPEC};
  # Replace slashes in the first argument ONLY (for Windows 98).
  # In the first only, because arguments may contain slashes (e.g. subst R: /d).
  $com =~ s{^(\s*")([^"]*)(")}{$1 . normSlashes($2) . $3}se
  	or $com =~ s{^(\s*)(\S+)}{$1 . normSlashes($2)}se;
  # Strip ["] for non-spaced commands, because miniperl does not support it in some (?) systems.
  $com =~ s/^\s*"([^"\s]*)"/$1/sg;
  my $cmd = "$com > \"$tmp\"";
  debug($cmd);
  system($cmd);
  $ENV{PATH} = $svPath;
  my $r = readBinFile($tmp);
  debug($r);
  unlink($tmp);
  return $r;
}
}}}


# string getcwd()
# Returns the current directory path.
sub getcwd() {  
  if (exists $Win32::{GetCwd}) {
    # Old Perl versions may not support this, so check.
    return Win32::GetCwd();
  } else {
    my ($d) = getComOutput("dir") =~ /\s+(\w:\\.*)/m;
    $d =~ s/\s+$//s if $d;
    return $d||".";
  }
}


# string getMappedPath(string $drive)
# Returns the host directory for specified drive (\w:).
sub getMappedPath($)
{ my ($drive) = @_;
  my $out = getComOutput("subst");
  my ($dir) = $out =~ /^$drive\W*(.*)/mi;
  $dir =~ s/\s+$//s if $dir;
  return $dir||$drive;
}


# string expandMappedPath(string $path)
# Returns the path after all subst refs are expanded.
sub expandMappedPath($)
{ my ($path) = @_;
  my $before = $path;
  while (1) {
    if ($path !~ m{^(\w+:)?[/\\]}s) {
      # Absolutize.
      $path = getcwd() . "\\" . $path;
    }
    if ($path =~ m{^(\w+:)[/\\](.*)$}s) {
      # Replace subst drive letter to an absolute path.
      my ($drive, $dir) = ($1, $2);
      my $mapped = getMappedPath($drive);
      $mapped =~ s{[/\\]+$}{}sg;
      $path = $mapped . "/" . $dir;
    }
    return $path if $path eq $before;
    $before = $path;
  }
}


# string findFirst(@files)
# Return the first existing file from the list.
sub findFirst
{ my (@folders)=@_;
  foreach (@folders) {
    return $_ if defined $_ && -e $_;
  }
  return undef;
}


# list fsgrep(sub($basename, $fullpath), $path)
# Search for file or directory with callback-matched names from $path (recurrent).
sub fsgrep(&$);
sub fsgrep(&$)
{ my ($test, $path) = @_;
  my @found = ();
  if (-d $path) {
    opendir(local *D, $path) or return;
    foreach my $e (readdir D) {
      next if $e eq "." || $e eq "..";
      my $full = "$path/$e";
      local $_ = $e;
      if ($test->($full)) {
        my $p = $full; $p =~ s{/}{\\}sg;
        push @found, $p;
      }
      push @found, &fsgrep($test, $full);
    }
  }
  return wantarray? @found : $found[0];
}


# list dirgrep(sub($basename, $fullpath), $path)
# Search for file or directory with callback-matched names in directory $path (no recurse).
sub dirgrep(&$)
{ my ($test, $path) = @_;
  return if !-d $path;
  opendir(local *D, $path) or return;
  foreach my $e (readdir D) {
    next if $e eq "." || $e eq "..";
    my $full = "$path/$e";
    local $_ = $e;
    if ($test->($full)) {
      my $p = $full; $p =~ s{/}{\\}sg;
      push @found, $p;
    }
  }
  return wantarray? @found : $found[0];
}


# void fixedReplace(\$st, $re, $to)
# Return the part of $st (passed by reference) mathing to regular
# expression $re to $to. If $to is shorter than match, trailing
# area is filled by zerro-coded characters.
sub fixedReplace
{ my ($rst,$re,$to)=@_;
  $$rst=~s{($re)}{
    $to.(chr(0)x(length($1)-length($to)));
  }seg;
}


{{{{
# Table Win1251->Other recoding.
my %Win2Other = (
  k =>  "\xc1\xc2\xd7\xc7\xc4\xc5\xa3\xd6\xda\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd2\xd3\xd4\xd5\xc6\xc8\xc3\xde\xdb\xdd\xdf\xd9\xd8\xdc\xc0\xd1\xe1\xe2\xf7\xe7\xe4\xe5\xb3\xf6\xfa\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf2\xf3\xf4\xf5\xe6\xe8\xe3\xfe\xfb\xfd\xff\xf9\xf8\xfc\xe0\xf1",
  w =>  "\xe0\xe1\xe2\xe3\xe4\xe5\xb8\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\xc0\xc1\xc2\xc3\xc4\xc5\xa8\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf",
  i =>  "\xd0\xd1\xd2\xd3\xd4\xd5\xf1\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xb0\xb1\xb2\xb3\xb4\xb5\xa1\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf",
  a =>  "\xa0\xa1\xa2\xa3\xa4\xa5\xf1\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\x80\x81\x82\x83\x84\x85\xf0\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f",
  d =>  "\xa0\xa1\xa2\xa3\xa4\xa5\xf1\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\x80\x81\x82\x83\x84\x85\xf0\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f",
  m =>  "\xe0\xe1\xe2\xe3\xe4\xe5\xde\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xdf\x80\x81\x82\x83\x84\x85\xdd\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f",
  t =>  "abvgdeegziyklmnoprstufh'''''i'euaABVGDEEGZIYKLMNOPRSTUFH'''''I'EUA"
);


# string ConvertCyrString(string $st, string $from, string $to)
# Recoder the string from Win1251 to $to. Valid values of $from & $to:
# k - koi8-r
# w - windows-1251
# i - iso8859-5
# a - x-cp866
# d - x-cp866
# m - x-mac-cyrillic
sub ConvertCyrString($$$)
{ my ($st,$from,$to)=@_;
  if(!defined $Win2Other{$from} || !defined $Win2Other{$to} || $from eq $to) { return $st; }
  eval "\$st=~tr/$Win2Other{$from}/$Win2Other{w}/;";
  eval "\$st=~tr/$Win2Other{w}/$Win2Other{$to}/;";  
  return $st;
}
}}}}


sub inet_aton($)
{ my ($ip) = @_;
  return join "", map { chr } split /\./, $ip;
}


sub inet_ntoa($)
{ my ($n) = @_;
  return join ".", map { ord } split //, $n;
}


sub pack_sockaddr_in($$)
{ my ($port, $a) = @_;
  return pack("sna4x8", AF_INET, $port, $a);
}


sub unpack_sockaddr_in($)
{ my ($sin) = @_;
  my @parts = unpack("sna4x8", $sin);
  return ($parts[1], $parts[2]);
}


# Flushes the filehandle buffer.
# Usage: flush(\*HANDLE)
sub flush {
	my ($fh) = @_;
    my $oldfh = select($fh); 
    $| = 1; 
    select($oldfh);
}


# bool chechSocketIfRunning($port)
# Checks localhost for open port $port.
sub chechSocketIfRunning 
{ my ($port) = @_;
  local $SIG{__WARN__} = sub{}; # to avoid undef warning after send()
  local *SOCK;
  my $test = "This is the test string";
  return
    socket(SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp')) &&
    connect(SOCK, pack_sockaddr_in($port, inet_aton("127.0.0.1"))) &&
    send(SOCK, $test, 0) > length($test)-2; # or -3, or -4 etc.
}


# string getToolExePath(string $exeName)
# Returns the full path to tool EXE.
sub getToolExePath {
  my ($exe) = @_;
  return expandMappedPath(dirname(__FILE__)."/exe/$exe");
}


# [ { pid=>..., exe=>... }, ... ] getPs($dontDieOnError=false)
# Returns the result of PS command. Returns undef 
# if PS.exe not found (or dies if $dontDieOnError=false).
sub getPs {
  my ($dontDieOnError) = @_;
  my @ps_pathes = (getToolExePath("ps.exe"));
  foreach my $ps (@ps_pathes) {
    $ps =~ s{/}{\\}sg; next if !-f $ps;
    my $out = getComOutput("\"$ps\"") or next;
    my @ps = ();
    foreach my $line (split /(?:\r?\n)+/s, $out) {
      my ($pid, $exe) = $line=~/^\s* ([0-9a-z-]+) \s+ ([^\n\r]+)/mix; 
      push @ps, { pid=>$pid, exe=>$exe };
    }
    return \@ps;
  }
  # PS.exe not found.
  return if $dontDieOnError;
  die "No ps.exe found in ".join(", ",@ps_pathes)."!\n";
}


# string getSFP($key)
# Interface to SHGetSpecialFolderPath (see MSDN).
sub getSFP {
  my ($key) = @_;
  my @pathes = (getToolExePath("getpath.exe"));
  foreach my $exe (@pathes) {
    $exe =~ s{/}{\\}sg; next if !-f $exe;
    my $out = getComOutput("\"$exe\" $key");
    $out =~ s/^\s+|\s+$//sg;
    next if !$out;
    return $out;
  }
  die "No getpath.exe found in ".join(", ",@pathes)."!\n";
}


# int gracefulKill($pid, int $timeout, string $signal)
# Sends WM_CLOSE (soft) or KILL (hard) signal to a process.
# Return value is:
# 0: process is killed
# 1: timed out, not killed
# 2: failed, not killed
sub gracefulKill {
  my ($pid, $signal, $timeout) = @_;
  my $sender = getToolExePath("terminate.exe");
  die "No $sender found!\n" if !-f $sender;
  getComOutput("$sender $pid $timeout $signal");
  return $? >> 8;
}


# Returns true is process with PID does exist.
# Return false if pid is not specified or process does not exist.
# Stupid Perl 5.8 kill() kas a bug sending 0 signal, so we use ps.exe always.
sub checkProcessIfRunning
{ my ($pid,$name) = @_;

  $pid=~s/^\s+|\s+$//sg if $pid;
  return 0 if !$pid;

  # No such process?
  return 0 if !kill(0,$pid);

  my $ps = getPs(1);
  return 1 if !$ps; # PS.exe not found, but PID exists.

  # Try to match PID with its $name.
  foreach my $ps (@$ps) {
    next if $ps->{pid} ne $pid;
    # Found process with $pid. Name match?
    return !$name || $ps->{exe}=~m{(^|\\|/)\Q$name\E$}is;
  }

  # Process not found.
  return 0;
}


# ({ pid=>..., exe=>... }, ...) searchForProcess($exeName)
# Searches for process with specified EXE name.
sub searchForProcesses 
{ my ($exe, $dontDieOnError) = @_;
  my $ps = getPs($dontDieOnError) or return;
  my @found = ();
  # for compatibility.
  $exe = basename($exe);
  foreach my $ps (@$ps) {
#   print "$ps->{pid}, $ps->{exe}\n";
    push @found, $ps if $ps->{exe}=~m{(^|\\|/)\Q$exe\E$}is;
  }
  return @found;
}


return 1;
