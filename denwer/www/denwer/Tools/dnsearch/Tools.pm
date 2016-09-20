# +-------------------------------------------------------------------------+
# | Small Functions Library (Tools.pm)                                      |
# | Version: 1.1 [2004-12-01]                                               |
# +-------------------------------------------------------------------------+
# | Copyright © Anton Sushchev aka Ant <http://forum.dklab.ru/users/Ant/>   |
# +-------------------------------------------------------------------------+
# | List of all functions:                                                  |
# | ~~~~~~~~~~~~~~~~~~~~~~                                                  |
# |   — readTextFile ( $file )                                              |
# |   — writeTextFile( $file, $data )                                       |
# |   — readBinFile  ( $file )                                              |
# |   — writeBinFile ( $file, $data )                                       |
# |   — parseTypes   ( $file )                                              |
# |   — strXhtmlValid( $str )                                               |
# |   — ceil         ( $number )                                            |
# |   — dozenRand    ()                                                     |
# |   — getQuery     ()                                                     |
# |   — filesList    ( $path )                                              |
# +-------------------------------------------------------------------------+


package Tools;
#use strict;

sub readTextFile ($) {
	open( local *FILE, "<$_[0]" ) or return;
		eval { flock( FILE, 1 ) };
		undef( local $/ );
		my $text = <FILE>;
		eval { flock( FILE, 8 ) };
	close( FILE ) or return;
	return $text;
}

sub writeTextFile ($$) {
	open( local *FILE, ">>$_[0]" ) or return;
		eval { flock( FILE, 2 ) };
		print FILE $_[1];
		eval { flock( FILE, 8 ) };
	close( FILE ) or return;
	return 1;
}

sub readBinFile ($) {
	open( local *FILE, "<$_[0]" ) or return;
		eval { flock( FILE, 1 ) };
		binmode( FILE );
		undef( local $/ );
		my $text = <FILE>;
		eval { flock( FILE, 8 ) };
	close( FILE ) or return;
	return $text;
}

sub writeBinFile ($$) {
	open( local *FILE, ">>$_[0]" ) or return;
		eval { flock( FILE, 2 ) };
		binmode( FILE );
		print FILE $_[1];
		eval { flock( FILE, 8 ) };
	close( FILE ) or return;
	return 1;
}

# Parsing types file.
sub parseTypes ($) {
	my %hash;
	for ( split( /\n/, Tools::readTextFile( $_[ 0 ] ) ) ) {
		s/(?:#|;|\/\/)(?:.*)$//;   # remove comments
		s/^\s+|\s+$//g;            # remove beginning and trailing white spaces
		next if /^$/;
		/^([^\s]+)\s+?([^\s].*)$/; # search pairs: key-value
		if ( defined( $1 ) and defined( $2 ) ) { $hash{ $1 } = $2 }
	}
	return %hash;
}

# XHTML well-formed.
sub strXhtmlValid ($) {
	$_[0] =~ s/&(?!amp;)/&amp;/g;
	$_[0] =~ s/</&lt;/g;
	$_[0] =~ s/>/&gt;/g;
	return $_[0];
}

# Like PHP function ceil().
sub ceil ($) {
	if ( int( $_[0] ) < $_[0] ) {
		return int( $_[0] ) + 1;
	} else {
		return $_[0];
	}
}

# The dozen randomize numbers.
sub dozenRand {
	substr( time(), -6 ).int( rand( 100000 ) )
}

# Parsing CGI query. If there's file to upload, then uploading file.
# If there're many values for one name then creating anonymous array.
{{{
my $cache; # «cache» for next calls
sub getQuery {
	return %$cache if $cache;
	my ( $buffer, %in );

	# «multipart/form-data» request.
	if ( $ENV{ 'CONTENT_TYPE' } and $ENV{ 'CONTENT_TYPE' } =~ m{^multipart/form-data} ) {
		if ( $ENV{'REQUEST_METHOD'} ne 'POST' ) { return } # wrong request for «multipart/form-data»

		# Read STDIN to buffer.
		binmode( STDIN ); seek( STDIN, 0, 0 ); read( STDIN, $buffer, $ENV{ 'CONTENT_LENGTH' } );
		my $boundary = "--".( $ENV{ 'CONTENT_TYPE' } =~ /boundary=("?)(\S+|[^"]+)\1/ )[ 1 ];
		$buffer = substr( $buffer, length( $boundary ), index( $buffer, $boundary."--\x0D\x0A" ) - length( $boundary ) );

		# Parse buffer.
		for ( split( /$boundary\x0D\x0A/, $buffer ) ) {
			   $_      = substr( $_, 0, length( $_ ) - 2 );
			my $pos    = index( $_, "\x0D\x0A\x0D\x0A" );
			my $header = substr( $_, 0, $pos );
			my $value  = substr( $_, $pos + 4 );
			my $name   = ( $header =~ /\bname=("?)([^\s:;]+|[^"]+)\1/     )[ 1 ];
			my $fname  = ( $header =~ /\bfilename=("?)([^\s:;]+|[^"]*)\1/ )[ 1 ];
			  #$fname  = substr( $fname, rindex( $fname, "\\" ) + 1 ) if $fname;

			# Uploading file.
			if ( $header =~ /filename=/i ) {
				if ( $in{ $name } ) {
					if ( ref $in{ $name }[ 0 ] ) {
						push( @{ $in{ $name } }, [ $fname, $value ] )
					} else {
						my @temp = delete( $in{ $name } );
						push( @{ $in{ $name } }, @temp, [ $fname, $value ] );
					}
				} else { $in{ $name } = [ $fname, $value ] }
			# Usual variable.
			} else {
				if ( $in{ $name } ) {
					if ( ref $in{ $name } ) {
						push( @{ $in{ $name } }, $value )
					} else {
						my $temp = delete( $in{ $name } );
						push( @{ $in{ $name } }, $temp, $value );
					}
				} else { $in{ $name } = $value }
			}
		}
	# Usual request.
	} else {
		if ( $ENV{ 'REQUEST_METHOD' } eq "POST" ) { read( STDIN, $buffer, $ENV{ 'CONTENT_LENGTH' } ) }
		$buffer .= $buffer ? $ENV{ 'QUERY_STRING' } : '&'.$ENV{ 'QUERY_STRING' };

		$buffer =~ s/&(?!amp;)/&amp;/g; # XHTML standard
		for ( split( /&amp;/, $buffer ) ) {
			my ( $name, $value ) = split( /=/ );
			if ( $name ) {
				for ( $name, $value ) {	tr/+/ /; s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg; }
				if ( $in{ $name } ) {
					if ( ref $in{ $name } ) {
						push( @{ $in{ $name } }, $value )
					} else {
						my $temp = delete( $in{ $name } );
						push( @{ $in{ $name } }, $temp, $value );
					}
				} else { $in{ $name } = $value }
			}
		}
	}
	$cache = \%in;
	return %$cache;
}}}}

# Return size of given directory (including embedded
# directories) and list of all files inside. If «$_[1] > 0»
# (the second argument) then delete all content.
sub filesList {
	my $start_dir = $_[ 0 ];
	my ( $number, $size ) = ( 0, 0 );
	my ( @directories, @files, @dir );

	return if !$start_dir or !-d $start_dir;

	# Collection directories.
	$directories[ 0 ] = $start_dir;
	for ( my $i = 0; $i <= $number; $i++ ) {
		opendir( local *DIR, $directories[ $i ] );
			@dir = readdir( DIR );
		closedir( DIR );
		for ( my $k = 0; $k <= $#dir; $k++ ) {
			if ( $i == 0 ) { local $/ = '/'; chomp $directories[ 0 ]; }
			if ( -d "$directories[ $i ]/$dir[ $k ]" and $dir[ $k ] ne '.' and $dir[ $k ] ne '..' ) {
				$directories[ ++$number ] = "$directories[ $i ]/$dir[ $k ]"
			}
		}
	}

	# Collection files.
	$directories[ 0 ] = $start_dir;
	@directories = sort( @directories );
	for ( my $i = 0; $i <= $number; $i++ ) {
		opendir( local *DIR, $directories[ $i ] );
			@dir = readdir( DIR );
		closedir( DIR );
		for ( my $k = 0; $k <= $#dir; $k++ ) {
			if ( $i == 0 ) { local $/ = '/'; chomp $directories[ 0 ]; }
			if ( !-d "$directories[ $i ]/$dir[ $k ]" ) {
				$size += ( stat( "$directories[ $i ]/$dir[ $k ]" ) )[ 7 ];
				push( @files, "$directories[ $i ]/$dir[ $k ]" )
			}
		}
	}

	# Removing all directories.
	if ( $_[ 1 ] ) {
		unlink( @files );
		for ( my $i = $#directories; $i >= 0; $i-- ) { rmdir $directories[ $i ] }
	}

	return $size, @files;
}

return 1;
