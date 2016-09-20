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

package Installer;
$VERSION = 3.00;
use Tools;
use Interface;

# Constants.
my $CONFIG_NAME = "CONFIGURATION.txt";
my $NO_OVER = ".no_overwrite";

# Global configuration variables.
%CNF=();


# Экспортирует все функции в вызвавший пакет. Вызывается автоматически.
sub import {
  while(my ($k,$v)=each(%{__PACKAGE__."::"})) { 
    next if substr($k,-1) eq ":" || grep { $k eq $_ } qw(BEGIN import);
#   print "Export: ".caller()."::$k, $v\n";
    *{caller()."::".$k}=$v;
  }
}


# void copyTree($drom,$to,&$retry($error),\@exclude)
# Копирует дерево каталогов. Если очередной файл скопировать
# не удается, вызывается &$retry с сообщением об ошибке:
# если она возвращает 1, копирование повторяется, если 0, 
# то файл попускается. В @exclude хранится список регулярных
# выражений для искдючаемых из копирования путей. Также
# вместо РЕ может задаваться ссылка на функцию-предикат.
sub copyTree
{ my ($from,$to,$retry,$exclude,$deep)=@_;
  $retry ||= sub { die "$_[0]!\n" };
  $exclude ||= [];

  opendir(local *D,$from) or die "Could not open the directory $from!\n";
  my @list=readdir(D);
  closedir(D);

  # Check if we should not overwrite some files.
  my @noOver = ();
  if(-f (my $f="$from/$NO_OVER")) {
    if(open(local *F, $f)) {
      while(<F>) {
        s/^\s+|\s+$//sg; next if $_ eq "";
        push @noOver, $_;
#       print ">>> $from: '$_'\n";
      }
    }
  }

  mkTree($to) if !$deep;
  INNER:
  foreach my $f (@list) {
    next if $f eq ".." || $f eq ".";
    next if lc $f eq lc $NO_OVER;

    my $f1="$from/$f";
    my $f2="$to/$f";

    # No overwrite?
    next if grep { -e $f2 && $f =~ /$_/is } @noOver;

    # Проверяем, не нужно ли исключить этот файл.
    foreach my $ex (@$exclude) {
      if(ref($ex) eq "CODE") {
        next INNER if &$ex($f1);
      } else {
        next INNER if $f1=~/$ex/is;
      }
    }

    if(-d $f1) {
      # Directory?..
      if(!-d $f2) {
        while(!mkdir($f2, 0777)) { &$retry("Could not create the directory $f2") or next INNER }
      }
      copyTree($f1,$f2,$retry,$exclude,($deep||0)+1);1
    } else {
      # File?..
      progress("  $f2",70);
      local (*F1,*F2);
      while(!open(F1,$f1)) { &$retry("Could not open $f1") or return }
      binmode(F1);
      while(!open(F2,">$f2")) { &$retry("Could not create $f2") or return }
      binmode(F2);
      for(my $i=0; sysread(F1,my $buf,1024*16); $i++) {
        syswrite(F2, $buf, length($buf));
        progress(("/","-","\\","|")[$i%4],2);
      }
    }
    utime((stat $f1)[8],(stat $f1)[9],$f2);
  }
  if(!$deep) {
    progress("",70);
  }
  return 1;
}


# bool mkTree($dir)
# Создает все дерево каталога, имя которого указано в $dir.
sub mkTree
{ my ($dir)=@_;
  my @paths;
  for(my $d=$dir; $d!~m{^(\w:|/|\\)$}; $d=dirname($d)) { 
    unshift @paths,$d;
  }
  my $ok=1;
  map { !-e $_ and $ok=mkdir($_,0666) } @paths;
  return $ok;
}


my $manualConfDir=undef;
# void setConfigDir($dir)
# Sets the config file directory manually.
# Call with undef argument to search it automatically (default).
sub setConfigDir
{ my ($dir)=@_;
  $manualConfDir=$dir;
}


# void findConfig()
# Returns the full path to configuration file.
sub findConfig {
  return "$manualConfDir/$CONFIG_NAME" if $manualConfDir;
  my $dir=getcwd();
  for(my (@prev,@cur)=(1); join(":",@cur) ne join(":",@prev); $dir.="/..") {
    @prev=@cur;
    opendir(local *D,$dir) or last; @cur=readdir(D); closedir(D);
    my $path="$dir/$CONFIG_NAME";
    return $path if -f $path;
  }
  return dirname(__FILE__)."/../../$CONFIG_NAME";
}


# void reloadConfig()
# Loading the configuration to %CNF.
sub reloadConfig {
  %CNF=();
  open(local *F, findConfig()) or return;
  while(<F>) {
    s/#.*|^\s+|\s+$//sg;
    my ($k,$v)=split(/\s*=\s*/,$_,2); next if !defined $v;
    $v=~s/^"(.*)"$/$1/s;
    $CNF{$k}=$v;
  }
}
# Loading the configuration NOW.
reloadConfig();


# void saveConfig()
# Saves the configuration file from %CNF.
sub saveConfig {
  # First read the previous config.
  my $orig=readBinFile(my $confPath=findConfig()) or return;
  my $cnf=$orig;
  return if $cnf eq "" && !scalar keys %CNF;
  $cnf=~s/\s+$//s;
  foreach my $k (sort keys %CNF) {
    my $v=$CNF{$k}; next if !defined $v;
    $cnf=~s/\Q$k\E\s*=[^\r\n]*/$k = $v/m
      or $cnf.="\r\n$k = $v";
  }
  $cnf.="\r\n" if $cnf!~/\n$/s;
  writeBinFile($confPath,$cnf) if $orig ne $cnf;
}


# Saving before finishing script.
END { saveConfig() }


# string getSubstDriveConfig()
# Returns the root drive (substed or real if installed to the root).
sub getSubstDriveConfig {
  my $d = $CNF{subst_drive};
  my ($curDrive) = getcwd() =~ m/^(\w)/s;
  $d =~ s/\?/$curDrive/s;
  return $d;
}


# bool dirLikeRoot($dir)
# Возвращает true, если директория очень похожа на корневую.
sub dirLikeRoot
{ my ($dir)=@_;
  opendir(local *D,$dir); my @cur=readdir(D); closedir(D);
  $dir=~s{[/\\]+$}{}s;
  return scalar(
    (grep { -d "$dir/$_" && lc $_ eq "home" } @cur) &&
    (grep { -d "$dir/$_" && lc $_ eq "usr" } @cur) &&
    (grep { -d "$dir/$_" && lc $_ eq "denwer" } @cur)
  );
}

# bool dirLikeWindows($dir)
# Returns true if directory looks like Windows-directory.
sub dirLikeWindows 
{ my ($dir) = @_;
  $dir=~s{[/\\]+$}{}sg;
  $dir=~s/^\s+|\s+$//sg;
  return
    -d $dir && (
      (-d "$dir/system" && -f "$dir/system/kernel32.dll" && -f "$dir/system/user32.dll")
      ||
      (-d "$dir/system32" && -f "$dir/system32/kernel32.dll" && -f "$dir/system32/user32.dll")
    );
}

# @notFound getNotFoundFiles($dir, \@files, \@dirs)
# Returns list of not found objects (among @files, @dirs) if $dir.
sub getNotFoundFiles
{ my ($dir, $files, $dirs) = @_;
  return (
    grep { !-f "$dir/$_" } @{$files||[]},
    grep { !-d "$dir/$_" } @{$dirs||[]}
  );
}

# string findAutorun()
# Возвращает путь к папке Автозагрузка.
sub findAutorun {
  return getSFP("CSIDL_STARTUP");
}

# string findDesktop()
# Возвращает путь к папке Рабочий стол.
sub findDesktop {
  return getSFP("CSIDL_DESKTOPDIRECTORY");
}

my $cacheWinDir = undef;
sub findWindows {
  my $dir = findFirst($ENV{SystemRoot}, $ENV{WINDIR}, "C:\\Windows", "C:\\WinNT");
  return $dir if $dir;
  return $cacheWinDir if $cacheWinDir;
  print "ЌҐ г¤ «®бм ®Ў­ аг¦Ёвм ¤ЁаҐЄв®аЁо Windows!\n";
  while(1) {
    print "€¬п ¤ЁаҐЄв®аЁЁ б Windows: ";
    $dir=trim(scalar <STDIN>);
    $dir=~s{[\\/]+$}{}sg;
    if(!dirLikeWindows($dir)) {
      print "ќв® ­Ґ ¤ЁаҐЄв®аЁп Windows!\n\n";
      next;
    }
    return $cacheWinDir = $dir;
  }
}

# void makeExeLink($template, $to, %opts)
# Создает EXE-ссылку (имя файла шаблона - в $template) с именем $to.
# Параметры %opts задают параметры, которые должны быть установлены.
# В EXE-файле каждому параметру должна соответствовать строка вида:
# \s* {param_key} [\s:]* [ .*? ]
sub makeExeLink
{ my ($templ, $to, %args)=@_;
  my $lnk=readBinFile($templ) or die "Could not open $templ\n";
  while(my ($k,$v)=each(%args)) {
    $lnk=~s{(\Q$k\E [\s:]* \[) (.*?) (\]) }{
      $1.$v.(substr($2,-1) x (length($2)-length($v))).$3
    }isxe;
  }
  writeBinFile($to,$lnk) or die "Could not create $to\n";
}


# void makeLink($template, $to, $path, $ico)
# Создает LNK-ссылку (имя файла шаблона - в $template) с именем $to,
# указывающую на программу $path. Если указан параметр $ico, то
# устанавливается также пиктограмма с путем $ico.
# Template ICO-file must be created in Win95 ONLY and contain
# the following pathes:
#   C:\aaaaaaaa...aaaaaaaa\VeryLongFileName.exe
#   C:\bbbbbbbb...bbbbbbbb\linkname.ico
# where ... - more than 35 a's. 
# Drive MUST be C: in this template!
sub makeLink
{ my ($templ, $to, $path, $ico)=@_;
  my $cont=readBinFile($templ) or die "Could not open $templ\n";
  $path=~s{/}{\\}sg;
  # First (!) process ICO.
  fixedReplace(\$cont, qr/[^\x00]+iconname.ico/si, $ico) if $ico;
  # Then process file path.
  my ($drive,$dir,$file) = $path=~m/^(\w):[\\\/](.*)[\\\/]([^\\\/]+)$/s;
  $cont=~s/C:\\/$drive:\\/sg;
  $dir=~s/^$drive://sg;
  fixedReplace(\$cont, qr/a{30,}\\VeryLongFileName.exe/si, "$dir\\$file");
  fixedReplace(\$cont, qr/a{30,}/s, $dir);
  fixedReplace(\$cont, qr/VeryLongFileName.exe/si, $file);
  writeBinFile($to,$cont) or die "Could not create $to\n";
  return 1;
}


return 1;