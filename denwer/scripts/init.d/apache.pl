#!perl -w
# +-------------------------------------------------------------------------+
# | Äæåíòëüìåíñêèé íàáîð Web-ðàçðàáîò÷èêà                                   |
# | Âåðñèÿ: Äåíâåð-3 2013-06-02                                             |
# +-------------------------------------------------------------------------+
# | Copyright (C) 2001-2010 Äìèòðèé Êîòåðîâ.                                |
# +-------------------------------------------------------------------------+
# | Äàííûé ôàéë ÿâëÿåòñÿ ÷àñòüþ êîìïëåêñà ïðîãðàìì "Äåíâåð-3". Âû íå ìîæåòå |
# | èñïîëüçîâàòü  åãî â êîììåð÷åñêèõ  öåëÿõ.  Íèêàêèå äðóãèå îãðàíè÷åíèÿ íå |
# | íàêëàäûâàþòñÿ.  Åñëè âû õîòèòå âíåñòè èçìåíåíèÿ â èñõîäíûé êîä,  àâòîðû |
# | áóäóò ðàäû ïîëó÷èòü îò âàñ êîììåíòàðèè è çàìå÷àíèÿ. Ïðèÿòíîé ðàáîòû!    |
# +-------------------------------------------------------------------------+
# | Äîìàøíÿÿ ñòðàíèöà: http://denwer.ru                                     |
# | Êîíòàêòû: http://forum.dklab.ru/denwer                                  |
# +-------------------------------------------------------------------------+

package Starters::Apache;
BEGIN { unshift @INC, "../lib"; }

use Tools;
use Installer;
use ParseHosts;
use VhostTemplate;
use StartManager;

# Seconds to wait apache stop while restart is active.
my $timeout = 10;

# Get common pathes.
my $basedir     = $CNF{apache_dir};
my $exe         = fsgrep { /\Q$CNF{apache_exe}\E/i } $basedir;
die "  Could not find $CNF{apache_exe} inside $basedir\n" if !$exe;
my $httpd_conf  = "$basedir/conf/httpd.conf";
my $vhosts_conf = "$basedir/conf/vhosts.conf";
my $httpd_pid   = "$basedir/logs/httpd.pid";

# Additional PATH entries.
my @addPath = ();
$ENV{'PATH'} = '\usr\local\vcredist;' . $ENV{'PATH'};

# Autoconfigure PHP - detect basedir from LoadModule in httpd.conf file.
my $phpdir = undef;
my $httpdCont = readBinFile($httpd_conf) or die "  Could not read $httpd_conf\n";
if ($httpdCont =~ /^[ \t]* LoadModule [ \t]+ php\S*_module [ \t]+ (?: "([^"\r\n]*)" | (\S+) )/mix) {
  my $path = dirname($1 || $2);
  if (my $p1 = dirgrep { /^php.ts\.dll$/i } $path) {
    $phpdir = dirname($p1);
  } elsif (my $p2 = dirgrep { /^php.ts\.dll$/i } "$path/..") {
    $phpdir = dirname($p2);
  }
}
if ($phpdir) {
  # PHP configuration file location.
  $ENV{PHPRC} = $phpdir;
  # For OpenSSL module in PHP.
  if (my $p = fsgrep { /^openssl.cnf$/i } $phpdir) {
    $ENV{OPENSSL_CONF} = $p;
  }
  # Set PATH.
  push @addPath, ($phpdir, fsgrep { /^extensions$/i || /^dlls$/i } $phpdir);
  # Correct timezone.
  my $iniFile = "$phpdir/php.ini";
  my $ini = readBinFile($iniFile);
  if ($ini) {
    my $version = `$phpdir\\php.exe -n -v`;
    if ($version =~ /^PHP\s+5\.[3-9]/s) {
      if ($ini !~ m/^\s*date.timezone/m) {
        my $zone = `$phpdir\\php.exe -n -r "echo \@date_default_timezone_get();"`;
        $zone =~ s/\s+$//sg;
        $directive = "date.timezone = $zone";
        $ini =~ s/^\s*;\s*date.timezone\s*=[^\r\n]*/$directive/m
          or $ini .= "\r\n$directive\r\n";
      }
#      $ini =~ s/^[\s;]*(register_long_arrays)[^\r\n]*/$1=Off/mg;
#      $ini =~ s/^[\s;]*(magic_quotes_gpc)[^\r\n]*/$1=Off/mg;
#      $ini =~ s/^\s*extension\s*=\s*php_pdo\.dll/;$&/mg;
      writeBinFile($iniFile, $ini);
    }
  }
}


StartManager::action 
  $ARGV[0],
  PATH => [
	'\usr\local\vcredist',
  	'\usr\local\ImageMagick',
  	@addPath,
  ],
  start => sub {
    ###
    ### START.
    ###
    processVHosts();
    print "‡ ¯ãáª ¥¬ Apache...\n";
    if(checkApacheIfRunning()) {
      print "  Apache ã¦¥ § ¯ãé¥­.\n";
    } else {
      chdir($basedir);
      my $exe = $exe;
      if(!-f $exe) {
        die "  ¥ ã¤ ¥âáï ­ ©â¨ $exe.\n";
      } else {
        # Clean global error.log to avoid stupid PHP "C:\mysql" binding.
        unlink("$basedir/logs/error.log");
        # Start apache.
        system("start $exe -w");
        print "  ƒ®â®¢®.\n";
      }
    }
  },
  stop => sub {
    ###
    ### STOP.
    ###
    print "‡ ¢¥àè ¥¬ à ¡®âã Apache...\n";
    if (!-f $exe) {
      print "  ¥ ã¤ ¥âáï ­ ©â¨ $exe.\n";
      return;
    }
    
    my $pid = trim(readTextFile($httpd_pid));
    if (!$pid || !checkApacheIfRunning()) {
      print "  Apache ­¥ § ¯ãé¥­.\n";
      return;
    }
    
    my $sender = getToolExePath("apachesignal.exe");
    if (!-f $sender) {
      print "  ¥ ã¤ ¥âáï ­ ©â¨ $sender!\n";
      return;
    }
    
    my $result = getComOutput("$sender -p $pid -k stop");
    if ($? >> 8) {
      $result =~ s/^/  /mg;
      print "  Žè¨¡ª  ®â¯à ¢ª¨ á¨£­ «  § ¢¥àè¥­¨ï:\n";
      print $result;
      return;
    }
    print "  ƒ®â®¢®.\n";
  },
  
  _middle => sub {
    ###
    ### MIDDLE: after "start" of "restart".
    ###
    if (checkApacheIfRunning()) {
      $| = 1;
      print "Ž¦¨¤ ¥¬ § ¢¥àè¥­¨ï Apache (¬ ªá¨¬ã¬ $timeout á¥ªã­¤) ";
      my $tm = time();
      while (time() - $tm < $timeout) {
        print ". ";
        if (!checkApacheIfRunning()) {
          print "\n";
          print "  ƒ®â®¢®.\n";
          return;
        }
        sleep(1);
      }
      print "\n";
      print "  ¥ ã¤ ¥âáï ¤®¦¤ âìáï § ¢¥àè¥­¨ï!\n";
    }
  }
;


sub processVHosts {
  my $VHOSTS = $vhosts_conf;
  my $HTTPD = $httpd_conf;

  print "‘®§¤ ¥¬ ¡«®ª¨ ¢¨àâã «ì­ëå å®áâ®¢...\n";

  if(!-e $HTTPD) {
    die "  ¥ ã¤ ¥âáï ­ ©â¨ $HTTPD\n";
  }

  # Add comments.
  my $vhosts = '';
  $vhosts .= clean qq{
    #
    # ÂÍÈÌÀÍÈÅ!
    #
    # Äàííûé ôàéë áûë ñãåíåðèðîâàí àâòîìàòè÷åñêè. Ëþáûå èçìåíåíèÿ, âíåñåííûå â 
    # íåãî, ïîòåðÿþòñÿ ïîñëå ïåðåçàïóñêà Äåíâåðà. Åñëè âû õîòèòå èçìåíèòü
    # ïàðàìåòðû êàêîãî-òî îòäåëüíîãî õîñòà, âàì íåîáõîäèìî ïåðåíåñòè 
    # ñîîòâåòñòâóþùèé áëîê <VirtualHost> â httpd.conf (òàì íàïèñàíî, êóäà èìåííî).
    #
    # Ïîæàëóéñòà, íå èçìåíÿéòå ýòîò ôàéë.
    #
  };

  # Read Vhost template
  my $num = 1;
  foreach my $host (VhostTemplate::getAllVHosts($HTTPD)) {
#    use Data::Dumper; print Dumper($host);
    $vhosts .= "\n\n# Host ".$host->{path}." ($num): \n";

    my $s = $host->{vhost};
    # Delete comments.
    $s=~s/#.*//mg if $num!=1;
    $s=~s/^[ \t]*[\r\n]+//mg;    # delete empty lines

    # ‚áâ ¢«ï¥¬ ¡ãª¢ã ¤¨áª  - ¯à®ª«ïâë¥ à §à ¡®âç¨ª¨ PHP ¡¥§ íâ®£® ­¥ ¬®£ãâ ­¨ª ª!
    $s=~s{^(\s* DocumentRoot \s+ "?)(/)}{$1 . Installer::getSubstDriveConfig() . $2}mgxie;

    $vhosts .= $s;
  } continue {
    $num++;
  }

  # Remove duplicate Listen directives.
  my %dup = ();
  $vhosts =~ s{^\s* Listen \s+ "? ([^\s"]+) "?}{ ($dup{lc $1}++)? '#'.$& : $& }megx;

  # Remove duplicate NameVirtualHost.
  %dup = ();
  $vhosts =~ s{^\s* NameVirtualHost \s+ "? ([^\s"]+) "?}{ ($dup{lc $1}++)? '#'.$& : $& }megx;
  
  # Open output file.
  if(!open(local *F, ">$VHOSTS")) {
    out qq{
      ‚ˆŒ€ˆ…!
      ¥ ã¤ ¥âáï ®âªàëâì ä ©« $VHOSTS ­  § ¯¨áì. 
      à®¤®«¦¥­¨¥ à ¡®âë ­¥¢®§¬®¦­®.
    };
    waitEnter();
    die "\n";
  }
  print F $vhosts;
  close F;
  
  print "  „®¡ ¢«¥­® å®áâ®¢: ".($num-1)."\n";
}

sub checkApacheIfRunning {
  return !open(local *F, ">>$exe");
}

return 1 if caller;
