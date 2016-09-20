#!perl -w
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

##
## ��������!!!
## �� ���������������� ���� ������ � subst.pl!!!
## ���� Win2000 ������ � ������: subst.exe � subst.pl.
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
		������������������������������������������������������������Ŀ
		� �����襭 䠩� ���䨣��樨 ��⥬�: �� 㤠���� ����� ��� �
		� ����㠫쭮�� ��᪠. ��२��⠫����� ��������.            �
		��������������������������������������������������������������
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
		print "���樠������ ����㠫쭮�� ��᪠ $subst_drive...\n"; 

		if (!-d "$subst_drive\\") {
			my $found = searchForRoot();
			system(my $cmd="subst $subst_drive \"$found\"");

			# Check for success.
			if (!dirLikeRoot("$subst_drive\\")) {
				out qq{
					  ��������!
					  �� ��������� ��稭�� �� 㤠���� ��������� ����㠫�� ���.
					  �� �ࠡ�⠫� �������: $cmd.
					  �த������� ࠡ��� ����������.			  
				};
				waitEnter();
				exit(10);		
			}
			print "  ����� ������祭�� ����祭.\n";
		} else {

			# Disc is already created. Check if it looks like root.
			if (!dirLikeRoot("$subst_drive\\")) {
				out qq{
					  ��������!
					  ����㠫�� (��� ������㠫��) ��� $subst_drive 㦥 ������� 
					  � ��⥬�, � �� �� ��宦 �� ��୥��� ��⠫�� �ࢥ஢. 
					  ���஡�� �⪫���� ��� (�᫨ �� �⥢��), ��� ��ࠢ�� 
					  ���樣��樮��� 䠩� ��������. 
					  �த������� ࠡ��� ����������.
				};
				waitEnter();
				exit(11);	
			} else {
				print "  ��� 㦥 ������祭.\n";
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
		print "�⪫�祭�� ����㠫쭮�� ��᪠ $subst_drive...\n";

		if (-d "$subst_drive\\") {
			if (!dirLikeRoot("$subst_drive\\")) {
				print "  �� ��宦�, �� ��� ᮧ��� �������ᮬ, �ய�᪠��.\n";
			} else {
				my $dir = getMappedPath($subst_drive);
				chdir("$dir\\denwer") if $dir !~ /^\Q$subst_drive/;
				# Disconnect the disk off.
				system("subst $subst_drive /d");
				# Success?
				if(dirLikeRoot("$subst_drive\\")) {
					out qq{
					  �� 㤠���� �⪫���� ���. �� �� �訡��, ���� �।�०�����.
					  ����� ��� �뢠�� � ��⥬�� Windows 9x ��-�� �訡�� � subst.exe.
					  �� ����� ���஡����� ������ �������� ᫥���騩 䠩�:
					  $dir\\denwer\\SwitchOff.exe
					  ������ ��������. � �� ��砥, ��� �㤥� �⪫�祭 ��᫥ ��१���㧪�.
					};
				} else {
					print "  ����� �⪫�祭�� ����祭.\n";
				}
			}
		} else {
			print "  ��� 㦥 �⪫�祭.\n";
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