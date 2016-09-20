#!/usr/local/miniperl/miniperl -w
# +-------------------------------------------------------------------------+
# | Archive Viewer for DNSearch (Denwer Search)                             |
# | Version: 1.02 [2004-12-01]                                              |
# +-------------------------------------------------------------------------+
# | Copyright © Anton Sushchev aka Ant <http://forum.dklab.ru/users/Ant/>   |
# +-------------------------------------------------------------------------+


#use strict;
use Tools;

use Conf::DNSconf; # config here

################################################################################
#*******************************************************************************
#* НАСТРОЙКИ СКРИПТА
#*

# Путь к файлу «mime.types».
my $MIME_TYPES_FILE = 'Conf/mime.types';

################################################################################
#*******************************************************************************
#* ТЕЛО ПРОГРАММЫ
#*

# Фразы для подстветки.
my %hl = Tools::getQuery();

# Проверка файла «mime.types» на существование.
if ( !-e $MIME_TYPES_FILE ) { print "Content-Type: text/html; charset=windows-1251\n\nНе найден файл «mime.types»."; exit; }

# Чтение и разбор MIME-файла.
my %mime = Tools::parseTypes( $MIME_TYPES_FILE );

# Убеждаемся, что что-то было запрошено.
if ( !$ENV{ 'PATH_INFO' } ) { print "Content-Type: text/html; charset=windows-1251\n\nНет запроса."; exit; }

# Путь до запрашиваемого файла (относительно $ARCH_PATH).
my $file_path = $ENV{ 'PATH_INFO' };
$file_path =~ tr/+/ /; $file_path =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
$file_path =~ s/\0//g; $file_path =~ tr/&;`'\"|*?~<>^()[]{}$\n\r//d; $file_path =~ s/\.\.//g;
$file_path = $ARCH_PATH.$file_path;

# Содержимое запрашиваемого файла.
if ( !-e $file_path or -d $file_path ) { print "Content-Type: text/html; charset=windows-1251\n\nЗапрашиваемый файл не найден."; exit; }
my $src = Tools::readBinFile( $file_path );

# Размер запрашиваемого файла.
my $file_size = -s $file_path;

# Расширение запрашиваемого файла.
my ( $ext ) = $file_path =~ /^.*\.(.*)$/;

# Если не найден MIME-тип, то отдаём как «text/plain».
if ( !defined $mime{ $ext } ) { $mime{ $ext } = 'text/plain' }

# Подстветка текста.
if ( $ext =~ /(?:s|x)?html?$/i ) {
	$src = highlight( $src, %hl );
	$file_size = length( $src );
}

# Выдача запрашиваемого файла.
binmode( STDOUT );
print "Content-type: $mime{ $ext }\nContent-length: $file_size\n\n";
print $src;

################################################################################
#*******************************************************************************
#* ФУНКЦИИ
#*

# Highlighting text inside «<body>...</body>».
sub highlight {
	my ( $html, %hl ) = @_;
	my ( $t1, $t2, $t3, $color, $hl_begin, $hl_end, $pos, $temp_1, $temp_2, $counter );

	my $background_color = 0xFFFFFF;
	for ( sort { $hl{ $b } <=> $hl{ $a } } keys %hl ) {
		$background_color = ( $background_color + 0x906030 ) & 0xffffff;
		if ( ($background_color & 0x00FF00) > 0x008000 ) { $color = "black" }
		else                                             { $color = "white" }
		$hl{ $_ } = [ $hl{ $_ }, $color, sprintf( "%06X", $background_color ) ];
	}

	my $sum = 0;
	for ( keys %hl ) { $sum += $hl{ $_ }[ 0 ] }

	my $table = qq~
		<!-- DNSearch's results table. -->
		<table cellspacing="5" cellpadding="0" style="width:100%;background:#fff;border:5px #00c solid;" onclick="this.style.display='none';" title="Click to hide."><tr><td>
			<table style="width:100%;border:1px #000 solid;">
	~;
	for ( sort { $hl{ $b }[ 0 ] <=> $hl{ $a }[ 0 ] } keys %hl ) {
		my $td_1 = ( $hl{ $_ }[ 0 ] * 100 ) / $sum if $sum;
		my $td_2 = 100 - $td_1;
		$table .= qq~
				<tr>
					<td style="font:8pt Verdana;">$_</td>
					<td style="width:100%;">
						<table cellpadding="0" cellspacing="0" style="width:100%;height:8px;"><tr>
							<td style="width:${td_1}%;background:#$hl{$_}[2];"></td>
							<td style="width:${td_2}%;"><div style="border:1px #$hl{$_}[2] dotted;"></div></td>
						</tr></table>
					</td>
					<td style="font:8pt Verdana;">$hl{$_}[0]</td>
				</tr>
		~;
	}
	$table .= qq~
			</table>
			<div style="text-align:right;font:8pt Verdana;">Powered by DNSearch.<br />DNSearch is not responsible for content of this page.</div>
		</td></tr></table><br />
		<!-- The end of DNSearch's results table. -->
	~;

	my ( $text ) = $html =~ m{<body.*?>(.*)</body\n*>}ims;
	for ( keys %hl ) {
		$hl_begin = "<b style='color:$hl{$_}[1];background-color:#$hl{$_}[2];'>";
		$hl_end   = "</b>";
		$counter = 0; $temp_1 = $temp_2 = "";
		while ( $text =~ /$_/ig ) {
			$t1 = $`; $t2 = $&; $t3 = $';
			if ( $t1 =~ /<[^>]*$/ or $t3 =~ /^[^<]*>/ ) { next } else { $counter++ }
			$temp_1 = $t1.$hl_begin.$t2.$hl_end;

			if ( $temp_2 ) {
				substr( $temp_1, 0, $pos, $temp_2 );
				$temp_2 = $temp_1;
			} else { $temp_2 = $temp_1 }
			$pos = pos( $text );
		}
		if ( $counter ) { substr( $text, 0, $pos, $temp_2 ) }
	}
	$html =~ s{(<body.*?>).*(</body\n*>)}{$1$table$text$2}ims;

	return $html;
}

exit;
