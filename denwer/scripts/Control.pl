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


# Actions of reverse invoke order.
@ReverseSections = qw(stop switchoff);
@Actions = qw(start stop restart boot switchoff);

# First we must determine current directory path (absolute).
# We need it to correctly update @INC pathes.
# Suppose that this script called from its own directory.
my $cwd;
BEGIN { 
	$cwd = Win32::GetCwd();
	unshift @INC, "$cwd/lib";
}

# Now @INC is OK, load libraries.
use Interface;
use Tools;
use Installer;

# Check for command-line arguments
my $cfg = $ARGV[0];
my $act = $ARGV[1];
my $needStop = @ARGV>2;

# Only one parameter specified - maybe it's an action name?
if($cfg && grep { $_ eq $cfg } @Actions) {	
	$act = $cfg;
	$cfg = $CNF{runlevel} || "main";
	$needStop = @ARGV>1;
}


if(!$cfg || !$act) {
	$cfg ||= "<config_name>";
	$act ||= "<action>";
	print clean qq{
		Usage:
		  $0 $cfg $act
		Examples:
		  $0 main start
		  $0 reserve stop
		  $0 main restart

		You may omit <config_name> parameter - thus "runlevel" directive
		from /denwer/CONFIGURATION.txt will be used. For example,
		  $0 start
		  $0 stop

	};
	waitEnter();
	exit(1);
}

print( (my $s="‡ ЇгбЄ ¤Ґ©бвўЁп $act Є®­дЁЈга жЁЁ $cfg...")."\n");
print( ("Д" x length($s))."\n");

# Reversed order of run?...
my $needReverse = grep { $act=~/$_/i } @ReverseSections;

# Error flag.
my $wasError=0;

# If true, vdisk must exist.
my $vdiskMustExist = 0;

# Run the action.
my $err = "$cwd/../../tmp/control_error_log.txt";
{{{
	local *STDERR;
	open(STDERR, ">$err");
	open(STDERR_IN, "$err");
	$vdiskMustExist = 1 if $act ne "start" && $act ne "boot";
	eval { runAction("$cfg/$act") };
	close(STDERR);
}}}
unlink($err);

# Была ошибка?..
if($wasError) {
	my $n=20;
	print "\x07\n"; # BEEP!
	message qq{
		Found at least $wasError error(s).
		Waiting for $n seconds (press Ctrl+Break to exit now)
	};
	for(my $i=0; $i<$n; $i++) { print "."; sleep(1); }
	print "\n";
	exit;
}

# All done,
#print "Exiting...\n"; chdir("C:\\"); 

# Pause if we have third argument.
if($needStop) {
	waitEnter();
} else {
	print "\n‚бҐ б¤Ґ« ­®. †¤Ґ¬ 1 бҐЄг­¤г.\n";
	sleep(1);
}
### 
### THE END.
###



# void runAction($fname, $action, @ignore)
# Runs the section or script. Parameter @ignore specifies the script 
# names which would not be run.
my $uniq = 0;
sub runAction {
	eval { runAction_noErr(@_) };
	print STDERR $@ if $@;

	# flush(STDERR).
	my $oldfh=select(STDERR); $|=1; select($oldfh);

	# Handle errors.
	local $/;
	my $errors = <STDERR_IN>;
	if($errors && $errors!~/^\s*$/s) {
		my $lineLen = 75;
		$errors=~s/^\s+|\s+$//sg;
		# Split too long lines.
		$errors =~ s{^([^\n]{$lineLen,})$}{
			my $s = $1;
			$s =~ s{(.{1,$lineLen})(\s+|$)}{ 
				$1 . ($2? "\n  " : "")
			}sge;
			$s
		}mge;
		message($errors);
		$wasError++;
	}
}


sub runAction_noErr 
{	my ($name, $action, @ignore)=@_;
	# Determine action to pass to scripts if it is not specified,
	if(!$action) {
		foreach (@Actions) {
			if($name=~m{/\Q$_\E$} || $name=~m{(/|^)\Q$_\E/}) {
				$action = $_;
				last;
			}
		}
		if(!$action) {
			die "Could not determine action {".join("|",@Actions)."} for \"$name\".\n";
		}
	}

	# Changes the current directory. This should be on virtual disk.
	# If fail, virtual disc isn't created yet (no matter).
	if (chdir(my $d = Installer::getSubstDriveConfig() . "\\denwer\\scripts")) {
		$cwd = $d;                                                    
	} elsif ($vdiskMustExist) {
		error qq{
			‚Ёавг «м­л© ¤ЁбЄ „Ґ­ўҐа  ­Ґ Ї®¤Є«озҐ­.
			‚Ґа®пв­®, „Ґ­ўҐа ҐйҐ ­Ґ § ЇгйҐ­.
		};
		sleep(2);
		exit(1);
	}

	# Gets the real name of file or directory.
	my $full=getFname("$cwd/$name");
	if(!$full) {
		die "Could not find file or directory \"$name\".\n";
	}
	my $base=basename($full);

	# Check if we use directory name.
	if(-d $full) {                                                     
		# Run all the scripts in this directory.
		opendir(local *D, $full) or die "Could not open directory \"$full\"!\n";		
		foreach my $e (sort { $needReverse? $b cmp $a : $a cmp $b } readdir(D)) {
			next if $e eq ".." || $e eq "." || uc $e eq 'CVS';
			next if grep { $e=~m{(\d|_)\Q$_\E(\.|$)[^/]*$}si } @ignore;
			runAction("$name/$e",$action,@ignore);
		}
	} else {
		# This is the file: script or symlink.
		my $d=dirname($full);
		chdir($d) or die "Could not chdir to \"$d\"!\n";
		# Check file type.
		if($base=~/\.pl$/i) {
			# This is a Perl-script.
			undef $@;  
			local @ARGV = ($action);
			if (!do(basename($full)) && $@) {
				die $@;
			}
		} elsif($base!~/\./i) {
			# This is the symlink.
			open(local *F, $full) or die "Could not open $full!\n";
			defined(my $s=<F>) or die "Bad link $full!\n";
			$s=~s/^\s+|\s+$//sg;
			# Read other link parameters.
			my @ign = @ignore;
			while(<F>) {
				s/^\s+|\s+$//sg;
				push @ign, $1 if /^-\s*(\S+)/ || /^disable:\s*(\S+)/;
			}
			# Switch action if needed.
			my ($lnk,$act) = split /\s+/, $s, 2;
			runAction($lnk,$act||$action,@ign);
		} else {
			# Usual command.
			system(basename($full)." $action");
		}
	}
}


# string getFname($name)
# By partly specified name $name (may be stripped prefix of digits,
# "_" and extension suffix) returns full file name. If file not found,
# returns undef.
sub getFname
{	my ($name)=@_;
	my ($dir) = dirname($name);
	my ($nm)  = $name=~m{[/\\]([^/\\]+)$}i or return undef;
	opendir(local *D, $dir) or return undef;
	my @names = grep { $_=~/^(\w+_)?\Q$nm\E(\.|$)/si } readdir(D) or return undef;
	return $dir eq "."? $names[0] : "$dir/$names[0]";
}
