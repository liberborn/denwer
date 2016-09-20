##@Banner

package VhostTemplate;
$VERSION = 3.00;
use Tools;

# Domain name template.
my $DOMAIN_RE = qr/^[_0-9a-z.-]+$/i;

# Default IP-address.
my $DEF_IP = "127.0.0.1";

# Meta-info file name (in DocumentRoot)
my $META_FNAME = ".htaccess";

# Prefix of all the meta-directives (stripped).
my $META_PREFIX = qr/dnwr_?/s;

my $DRMATCH = "documentrootmatch";

# Default host template. MUST be commented!!!
my $DEF_TEMPLATE = clean q{
  #Listen $&{ip:-127.0.0.1}:$&{port:-80}
  #<VirtualHost *:*>
  #  # TEMPLATE NOT FOUND IN httpd.conf - USE DEFAULT.
  #  ## This is the meta-directive, used only by templating system.
  #  ## Specifies the template to match DirectoryRoot. You may
  #  ## use more than one instances of this directive.
  #  DocumentRootMatch "/home/(?!cgi-)(.*)/public_html^1"
  #  DocumentRootMatch "/home/(?!cgi-)(.*)^1/html/(.*)"
  #  DocumentRootMatch "/home/(?!cgi-)(.*)^1/domains/(?!cgi$|cgi-)(.*)"
  #  DocumentRootMatch "/var/www/html/(?!cgi-)~(.*)^1/(?!cgi$|cgi-)(.*)"
  #  DocumentRootMatch "/home/(?!cgi-)(.*)^1/(?!cgi$|cgi-)(.*)"
  #
  #  # Name of this server. Ignored in most cases.
  #  ServerName "%&"
  #   
  #  # Which domain names corresponds to this host.
  #  ServerAlias "%&/-www" "%&/-www/www"
  #
  #  # Root of all the documents.
  #  DocumentRoot "$&"  
  #
  #  # "Standard" script alias directive. Part ".." will be removed,
  #  # all the pathes will be absolute.
  #  ScriptAlias /cgi/ "$^1/cgi/"
  #  ScriptAlias /cgi-bin/ "$^1/cgi-bin/"
  #</VirtualHost>
};

# List of stripped meta-directives in httpd.conf (case insen).
# Value contains true if directive must be stripped.
my %STRIP_DIRECTIVES = (
  $DRMATCH => 1,
);


##
## Формат шаблона директории документов:
##   /выр1/выр2/.../вырN
## где вырI - регулярное выражение в формате PCRE.
## Первое совпадение (участок в скобках) в каждом имени директории
## будет рассматриваться как доменное имя.
##
## Далее в шаблоне можно использовать следующие подстановочные знаки:
## 1. $&    - полный путь к директории документов;
## 2. $^N   - путь, помеченный в шаблоне как ^N. Например, для шаблона
##            "/home/(.*)^2/(.*)", примененного к "/home/abc/def",
##            значение $^2 будет равно /home/abc.
##            Вообще, $ в начале свидетельствует о работе с ПУТЯМИ.
## 3. %&    - полное доменное имя;
## 4. %^N   - N-й компонент доменного имени.
##            Вообще, % говорит о работе с ДОМЕННЫМИ ИМЕНАМИ.
## 5. $&стр - подстановка значения директивы "dnwr_стр" из файла
##            .htaccess, находящегося в директории документов.
##            Директива наследуется: если в родительских каталогах
##            есть .htaccess, в котором она опрелена, то значение
##            по умолчанию берется оттуда. Текст "стр" не должен
##            состоять из одних только цифр.

# array of hash readVHostTemplate($path_to_httpd_conf, bool $delCom)
# Ищет в httpd.conf блоки <VirtualHost>, являющиеся шаблоном
# виртуального хоста, и возвращает их содержимое (список). Шаблон
# распознается по наличию хотя бы одного символа $ в нем.
# Если $delCom==true, то комментарии из шаблона удаляются.
sub readVHostTemplate
{ my ($conf,$delCom) = @_;
  # Reat the whole file.
  local $/;
# warn "!$conf";
  open(local *F,$conf) or die "Couldn't open $conf\n";
  my $text=<F>;
  close(F);

  # Scan all the virtual hosts.
  # Vhost template is #-block with <VirtualHost>...</VirtualHost>
  # and ALL PREPENDING #-lines started with directive or #-comment.
  my @hosts = ();
  while(1) {
    # Get the host.
    my $s = '[ \t]';  # space except newline
    $text =~ m{(
      (?: ^$s* \# $s* [a-z\#] [^\r\n]* \r?\n )*
      ^$s* \# $s* < $s* VirtualHost $s+
      .*?
      ^$s* \# $s* < $s* / $s* VirtualHost $s* >
    )}mixgs or last;
    my $h = $1;

    # Try to parse template.
    my %parsed = _parseVHostTemplate($h);
    next if !$parsed{is_template};

    # Save parsed.
    push @hosts, \%parsed;
  }
#  use Data::Dumper; warn Dumper(\@hosts);

  # Use standard template?
  return {_parseVHostTemplate($DEF_TEMPLATE)} if !@hosts;
  return wantarray? @hosts : $hosts[0];
}


# hash _parseVHostTemplate(string $template)
# Extracst some control directives from VirtualHost.
# Returns: {
#    orig              => original text
#    vhost             => modified VirtualHost
#    is_template       => vhost contains some stripped directives
#    ip                => [ip1, ...]
#    documentrootmatch => [value1, value2, ...]
# }
sub _parseVHostTemplate
{ my ($h)=@_;

  # Clean.
  $h=~s/^\r//sg;                # delete \r
  $h=~s/^\s*#//mg;              # delete prepended "#"
  $h=~s/\s*##.*//mg;            # delete double-comments (always)
  $h=~s/\s*#.*//mg if $delCom;  # delete comments
  $h=~s/^[ \t]*[\r\n]+//mg;    # delete empty lines

  my %res = ();
  $res{orig} = $h;
  my $is_template = 0;
  while (my ($dir,$strip) = each %STRIP_DIRECTIVES) {
    $dir = lc $dir;
    $h =~ s{^[ \t]* $dir [ \t]+ \"? (.*?) \"? ([ \t]|\#.*)* $}{
      push @{$res{$dir}||=[]}, $1;
      if($strip) {
        $is_template=1;
        "#$&"
      } else {
        $&
      }
    }megix;
  }
  if ($is_template) {
    # Emit DocumentRoot if not exists.
    if ($h !~ /^\s*DocumentRoot\s/mi) {
      $h =~ s/^(\s*\#\s*${DRMATCH}[^\r\n]+)/$1\n  DocumentRoot "\$&"/mi
        or 
      $h =~ s/([^\r\n]+)$/  DocumentRoot "\$&"\n$1/s;
    }
  }
  $res{vhost} = $h;
  $res{is_template} = $is_template;
  return %res;
}


# string gluePath($s1,$s2)
# Glues path from its parts $s1 and $s2.
sub gluePath
{ my $s = join "/", @_;
  $s=~s{[\\/]+}{/}sg;
  return $s;
}


# hash readMeta($doc_root)
# Reads meta data from specified DocumentRoot.
sub readMeta
{ my ($docroot) = @_;
  my %hash = ();
  my $up=dirname($docroot);
  if($up && $up ne $docroot) {
    %hash = readMeta($up);
  }
  open(local *F, "$docroot/$META_FNAME") or return %hash;
  while(<F>) {
    s/^\s+|\s+$//sg;
    # Do NOT use //x modifier here!!! else $META_PREFIX does not work!
    m/^(?:[#]+\s*)?$META_PREFIX(\S+)[\s=]+(.*)/s or next;
    my $key = $1; $key = lc $key;
    my $val = $2; $val =~ s/\s*#.*|\s+$//sg;
    $hash{$key} = $val;
  }
  return %hash;
}


# array of { $path, \@parts, @path_marks, meta-data } matchHome($pat,$root="/")
# Returns all the directories from $root matching pattern $pat.
#   $path       - full directory path
#   @parts      - matched domaint name parts (right to left!)
#   @path_marks - pathes, marked by ^N
#   @dom_marks  - domain names, marked by ^N
# Examples of $pat:
#   /home/(.*)^1/(.*)     -> @path_marks="/home/xxx", @dom_marks="xxx"
#   /home/d(.*)/(.*)^1    -> "d" is not within parts strings 
#   /home/(d.*)/(.*)^2    -> "d" within
# IP addresses are collected from files ".ip".
$level = 0;
sub matchHome
{ my ($pat, $root)=@_;
  local $level = $level + 1;
  
  # Split $pat by slashes.
  $pat = ~s/^\s+|\s+$//sg if !ref $pat;
  my @parts = ref $pat? @$pat : splitDirPattern($pat);

  # Process situation with drive name specified.
  if ($parts[0] =~ /^(\w:)$/s && !$root) {
    $root = "$1/";
    shift @parts;
  }
  $root ||= "/";
  
#  warn "-- root='".($root||"")."': ".join(" ", @parts)."\n";
 
  # Current processing part.
  my $cur = shift @parts;

  # Marked with ^N ^M ^K?
  my @marks;
  $cur =~ s{\^(\d+)}{
    push @marks, $1;
    "";
  }sge;

  # Read dir & close it immediately.
  opendir(local *D, $root) or return;
  my @dir = grep { !/^\.|^CVS$/ } readdir D;
  closedir(D);
  
#  warn "dir=".join(" ", @dir)."\n";

  # Current part re.
  my $re = eval { qr/^$cur$/si } or die "Invalid regexp /$cur/\n";

  my @hosts = ();
  foreach my $e (sort @dir) {
    # OK, matched. If $1 exisis, it is a domain part.
    my $full = gluePath($root,$e);
    -d $full or next;
    # Match part?
#    warn "$e - $re\n";
    next if $e !~ $re;
    my $dom = defined $1? $1 : "";
#   warn "--$dom $DOMAIN_RE\n";
    # Not a domain?
    next if $dom ne "" && $dom!~$DOMAIN_RE;
    my @dom = split /\./, $dom;
#   warn "$e - $re - @dom\n";
    my @next = ();
    if (@parts) {
      # Recurse.
      @next = matchHome(\@parts, $full);
    } else {
      # No recure: just add me.
      my %meta = readMeta($full);
      push @next, {
        path       => $full,
        parts      => [],
        path_marks => {},
        dom_marks  => {},
        %meta,
      };
    }
    foreach (@next) {
      push @{$_->{parts}}, @dom;
      foreach my $mark (@marks) {
        $_->{path_marks}{$mark} = $full;
        $_->{dom_marks}{$mark} = $dom if $dom ne "";
      }
    }
    push @hosts, @next;
  }
  # Assign IP addresses for some hosts (e.g. /home/192.168.0.1/...).
  if ($level == 1) {
    foreach (@hosts) {
      next if $_->{ip};
      my $ip = join ".", @{$_->{parts}};
      if ($ip =~ m/(?:\.|^) (\d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3}) (?:\.|$)/sx) {
        $_->{ip} = $1;
      }
    }
  }
  # All done.
  return @hosts;
}


# list splitDirPattern($pat)
# Correctly splits dorectory path patterns into parts. Examples:
#   /home/.*/domains          -> "home", ".*", "domains"
#   \home\(.*)\domains        -> "home", "(.*)", "domains"
#   \home\(?!\\.)(.*)\.*      -> "home", "(?!\.)", ".*"
#   /home/\\x20(.*)/.*        -> "home", "\x20(.*)", ".*"
# You have to DOUBLE shashes if you want them to be escapers.
# Single slash is the separator too (like '/').
sub splitDirPattern
{ my ($pat) = $_;
  # Doubled slashes are not separators. We need so large code 
  # to always capture slash pairs. Couldn't be shorter!
  $pat=~s{\\(.|$)}{$1 eq "\\"? $1 : "/$1"}sge; # single-\  -> /
  $pat=~s{\\\\}{\\}sg;                         # \\        -> \
  return grep { $_ ne "" } split m{/}s, $pat;  # split ONLY by '/'!
}


# string absPath_fname($path)
# Converts pathes like "abc/def/../a" to "abc/a" (strips "." and "..").
sub absPath_fname
{ my ($path)=@_;
  $path=~s{\\([^\\])}{$1}sg;
  $path=~s{\\\\}{\\}sg;
  my $trailslash = $path=~s{/$}{}sg;
  my @path = ();
  foreach (split m|/|, $path) {
    if ($_ eq "" || /^\w:$/) { push @path, $_ }
    elsif ($_ eq "..") { pop @path }
    elsif ($_ eq ".") {}
    elsif (/^-(.*)/) { pop @path if defined $path[-1] && $path[-1]=~/$1/si }
    else { push @path, $_ }
  }
  $path = join("/",@path);
  $path.="/" if $trailslash;
  return $path;
}


# string absPath_dns($dns)
# Converts:
#   "abc.def.ru/../gh"    -> "gh.def.ru"
#   "www.def.ru/-www"     -> "def.ru"
#   "www.def.ru/abc"      -> "abc.www.def.ru"
#   "www.def.ru/-www/abc" -> "abc.def.ru"
#   "abc.def.ru/-www"     -> "abc.def.ru"
sub absPath_dns
{ my ($dns) = @_;
  # Convert domain name to "file name" (to use absPath_fname).
  my ($pre,$post) = split(m|/|, $dns, 2);
  my $path = join("/", reverse split(m|\.|, $pre)).(defined $post? "/$post" : "");
  my $new = absPath_fname($path);
  # Convert back.
  return join ".", reverse split(m|/|, $new);
}


# string makeVHostByTemplate(\%data, string $tmpl)
# Substitutes all the metasymbols in the template using host data %data.
# %data is the data returned by matchHome().
sub makeVHostByTemplate
{ my ($data, $tmpl)=@_;
  # Process line by line, before comments.
  $tmpl =~ s{^ ([^#\r\n]*) }{
    my $tmpl = $1; # not a comment!
    # Extract metasymbols with surrounded characters.
    $tmpl =~ s{
      ( [^\"\s\#]*? )        # pre
      ( \$&|\%&|\$\^|\%\^ )  # axis
      (?:
        \{ 
          (\w*)                       # var name
            (:-)                        # modifier (":-" supported only)
          (.*?)                       # default value
        \}
        | (\w*)                     # simple var
      )
      ( [^\"\s\#:,]*)        # post
    }{
      my $pre     = $1;
      my $axis    = $2;
      my $op      = $4;
      my $post    = $7;
      my $modif   = undef;
      my $default = '?';
      if ($op) {
        $modif = $3;
        $default = trim($5);
      } else {
        $modif = lc $6;
      }
      my $result= "";
      if ($modif eq "" || $modif=~/^\d+$/) {
        my $text;
        if ($axis =~ s/^\$//) {   # $
          # Directory path.
          if ($axis =~ s/^\^//) { # $^
            # Reference to marked path part.
            $text = $data->{path_marks}{$modif||0};
            $text = $default if !defined $text || $text eq ''; 
          } else { # $&
            # Reference to all the path.
            $text = $data->{path};
          }
          $result = absPath_fname($pre.$text.$post);
        } elsif ($axis =~ s/^\%//) {
          # Domain name.
          if ($axis =~ s/^\^//) { # %^
            # Reference to domain name part.
            $text = $data->{dom_marks}{$modif||0};
            $text = $default if !defined $text || $text eq ''; 
          } else { # %&
            # Reference to all the domain name.
            $text = join(".", @{$data->{parts}});
          }
          $result = absPath_dns($pre.$text.$post, 1);
        } else {
          # Unknown?
          $result = $pre."?".$post;
        }
      } else {
        # Get inherited meta-variable (from .htaccess-es)
        $result = $pre.(exists $data->{$modif}? $data->{$modif} : $default).$post;
      }
      $result;
    }egxs; 
    $tmpl;
  }egxm;
  return $tmpl;
}


# list getAllVHosts($httpd_conf)
# Analyses templates in httpd.conf, then scan home directory
# and collect all the virtual hosts with their IP addreses.
# Returns array with full meta-info about each host, for example:
# array of {
#   'path'     => '/home/localhost/subdomain',
#   'template' => {
#     'orig'              => '<VirtualHost *:*> -original template text- </VirtualHost>',
#     'documentrootmatch' => ['/home/(?!cgi-)(.*)/(?!cgi)],
#     'is_template'       => 1,
#     'vhost'             => '<VirtualHost *:*> - without meta-directives- </VirtualHost>',
#   },
#   'vhost'    => '<VirtualHost ...> -resulted (expanded) vhost- </VirtualHost>',
#   'parts'    => ['subdomain', 'localhost']
#   'ip'       => ip-address from <VirtualHost> header
# }
my %getAllVHosts_cache = ();
sub getAllVHosts
{ my ($conf)=@_; 

  # Cache result to be faster.
  return @{$getAllVHosts_cache{$conf}} if $getAllVHosts_cache{$conf};

  # First parse templates.
  my @tmpls = readVHostTemplate($conf) or return;

  # Then scan home for all the templates.
  # Foreach template...
  my @vhosts = map { 
    my $tmpl = $_;
    # Foreach DocumentRoot mask...
    map {
      my @matches = matchHome($_);
#      use Data::Dumper; warn Dumper($_, \@matches);
      # Foreach directory matched this mask...
      map { 
        # Save template reference.
        $_->{template} = $tmpl; 
        $_ 
      } grep {
        !$_->{disabled}
      } @matches;
    } @{$_->{$DRMATCH}||[]}
  } @tmpls; 

  # Delete nested pathes (updirs are deleted if crossed).
  foreach my $h1 (@vhosts) {
    foreach my $h2 (@vhosts) {
      next if $h1==$h2 || $h1->{deleted} || $h1->{template} ne $h2->{template};
      $h2->{deleted}=1 if $h1->{path} ne $h2->{path} && index($h1->{path},"$h2->{path}/")==0;
#     warn "$h1->{path} - $h2->{path} - $h2->{deleted}\n";      
    }
  }
  @vhosts = grep { !$_->{deleted} } @vhosts;

  # Then expands the template.
  foreach (@vhosts) {
    $_->{vhost} = makeVHostByTemplate($_, $_->{template}{vhost});
    if ($_->{vhost} =~ m{^\s* < \s* VirtualHost \s+ \"? (\d+\.\d+\.\d+\.\d+ | \*) \s* (?: : \s* ([*\d]+) )?}mix) {
      $_->{ip} = $1 || "*";
      $_->{port} = $2 || "*";
    } else {
      warn "Invalid VirtualHost block for $_->{path}\n";
    }
  }

  # Localhost is always at the beginning, to handle http://127.0.0.1 requests.
  # Other hosts are sorted alphabethically.
  @vhosts = sort { 
    my ($aSn) = $a->{vhost} =~ /^\s* ServerName \s+ "?([^\s"]+)"?/imx; $aSn = lc($aSn||'');
    my ($bSn) = $b->{vhost} =~ /^\s* ServerName \s+ "?([^\s"]+)"?/imx; $bSn = lc($bSn||'');
    $aSn eq "localhost" && $bSn ne "localhost"? -1 :
      $aSn ne "localhost" && $bSn eq "localhost"? 1 :
        $aSn cmp $bSn;
  } @vhosts;

  foreach (@vhosts) {
    $_->{ip} = $DEF_IP if !$_->{ip} || $_->{ip} eq "*";
  }

  # All done. 
  return @{$getAllVHosts_cache{$conf}} = @vhosts;
}


# hash getAllVHosts_forHosts($conf)
# Does the same as function before, except returns hash "host"=>"ip addr",
# to place it to "hosts" file. Names of the hosts are extracted from
# "ServerName" and "ServerAlias" fields. For example,
# hash = {
#   'www.aaa.bbb'             => '127.0.0.2',
#   'localhost'               => '127.0.0.1',
#   'aaa.bbb'                 => '127.0.0.2',
#   'subdomain.localhost'     => '127.0.0.1',
#   'www.localhost'           => '127.0.0.1',
#   'www.subdomain.localhost' => '127.0.0.1'
# };
sub getAllVHosts_forHosts
{ my ($conf)=@_;
  my %hosts = ();
  foreach my $host (getAllVHosts($conf)) {
    # Extract ServerName & ServerAlias
    my @matches = $host->{vhost}=~m{^ [ \t]* (?:ServerName|ServerAlias) [ \t]+ (.*)}mgxi;
    my @names = map { s/^\s+|\s+$//sg; split /\s+/ } @matches;
    # Make name=>ip pairs.
    my $ip = $host->{ip} || $DEF_IP;
    foreach $name (@names) {
      $name =~ s/^"(.*)"$/$1/sg;
      $hosts{$name} = $ip;
    }
  }
  return %hosts;  
}

return 1;