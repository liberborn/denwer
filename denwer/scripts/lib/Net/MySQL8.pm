package Net::MySQL;

use 5.004;
use IO::Socket;
use Carp;
use vars qw($VERSION $DEBUG);
use strict;
$VERSION = '0.08';

use constant COMMAND_SLEEP          => "\x00";
use constant COMMAND_QUIT           => "\x01";
use constant COMMAND_INIT_DB        => "\x02";
use constant COMMAND_QUERY          => "\x03";
use constant COMMAND_FIELD_LIST     => "\x04";
use constant COMMAND_CREATE_DB      => "\x05";
use constant COMMAND_DROP_DB        => "\x06";
use constant COMMAND_REFRESH        => "\x07";
use constant COMMAND_SHUTDOWN       => "\x08";
use constant COMMAND_STATISTICS     => "\x09";
use constant COMMAND_PROCESS_INFO   => "\x0A";
use constant COMMAND_CONNECT        => "\x0B";
use constant COMMAND_PROCESS_KILL   => "\x0C";
use constant COMMAND_DEBUG          => "\x0D";
use constant COMMAND_PING           => "\x0E";
use constant COMMAND_TIME           => "\x0F";
use constant COMMAND_DELAYED_INSERT => "\x10";
use constant COMMAND_CHANGE_USER    => "\x11";
use constant COMMAND_BINLOG_DUMP    => "\x12";
use constant COMMAND_TABLE_DUMP     => "\x13";
use constant COMMAND_CONNECT_OUT    => "\x14";

use constant DEFAULT_PORT_NUMBER => 3306;
use constant BUFFER_LENGTH       => 1460;
use constant DEFAULT_UNIX_SOCKET => '/tmp/mysql.sock';


sub new
{
	my $class = shift;
	my %args = @_;

	my $self = bless {
		hostname   => $args{hostname},
		unixsocket => $args{unixsocket} || DEFAULT_UNIX_SOCKET,
		port       => $args{port}       || DEFAULT_PORT_NUMBER,
		database   => $args{database},
		user       => $args{user},
		password   => $args{password},
		timeout    => $args{timeout}  || 60,
		socket     => undef,
		salt                 => '',
		protocol_version     => undef,
		client_capabilities  => 0,
		affected_rows_length => 0,
	}, $class;
	$self->debug($args{debug});
	$self->_initialize;
	return $self;
}


sub query
{
	my $self = shift;
	my $sql = join '', @_;
	my $mysql = $self->{socket};

	return $self->_execute_command(COMMAND_QUERY, $sql);
}


sub create_database
{
	my $self = shift;
	my $db_name = shift;
	my $mysql = $self->{socket};

	return $self->_execute_command(COMMAND_CREATE_DB, $db_name);
}


sub drop_database
{
	my $self = shift;
	my $db_name = shift;
	my $mysql = $self->{socket};

	return $self->_execute_command(COMMAND_DROP_DB, $db_name);
}


sub close
{
	my $self = shift;
	my $mysql = $self->{socket};
	return unless $mysql->can('send');

	my $quit_message =
		chr(length(COMMAND_QUIT)). "\x00\x00\x00". COMMAND_QUIT;
	$mysql->send($quit_message, 0);
	$self->_dump_packet($quit_message) if Net::MySQL->debug;
	$mysql->close;
}


sub get_affected_rows_length
{
	my $self = shift;
	$self->{affected_rows_length};
}


sub get_insert_id
{
	my $self = shift;
	$self->{insert_id};
}


sub create_record_iterator
{
	my $self = shift;
	return undef unless $self->has_selected_record;

	my $record = Net::MySQL::RecordIterator->new(
		$self->{selected_record}
	);
	$self->{selected_record} = undef;
	$record->parse;
	return $record;
}


sub has_selected_record
{
	my $self = shift;
	$self->{selected_record} ? 1 : undef;
}


sub is_error
{
	my $self = shift;
	$self->{error_code} ? 1 : undef;
}


sub get_error_code
{
	my $self = shift;
	$self->{error_code};
}


sub get_error_message
{
	my $self = shift;
	$self->{server_message};
}


sub debug
{
	my $class = shift;
	$DEBUG = shift if @_;
	$DEBUG;
}


sub _connect
{
	my $self = shift;

	my $mysql;
	if ($self->{hostname}) {
		printf "Use INET Socket: %s %d/tcp\n", $self->{hostname}, $self->{port}
			if $self->debug;
		$mysql = IO::Socket::INET->new(
			PeerAddr => $self->{hostname},
			PeerPort => $self->{port},
			Proto    => 'tcp',
			Timeout  => $self->{timeout} || 60,
		) or croak "Couldn't connect to $self->{hostname}:$self->{port}/tcp: $@";
	}
	else {
		printf "Use UNIX Socket: %s\n", $self->{unixsocket} if $self->debug;
		$mysql = IO::Socket::UNIX->new(
			Type => SOCK_STREAM,
			Peer => $self->{unixsocket},
		) or croak "Couldn't connect to $self->{unixsocket}: $@";
	}
	$mysql->autoflush(1);
	$self->{socket} = $mysql;
}


sub _get_server_information
{
	my $self = shift;
	my $mysql = $self->{socket};

	my $message;
	$mysql->recv($message, BUFFER_LENGTH, 0);
	$self->_dump_packet($message)
		if Net::MySQL->debug;
	my $i = 0;
	my $packet_length = ord substr $message, $i, 1;
	$i += 4;
	$self->{protocol_version} = ord substr $message, $i, 1;
	printf "Protocol Version: %d\n", $self->{protocol_version}
		if Net::MySQL->debug;
	if ($self->{protocol_version} == 10) {
		$self->{client_capabilities} = 1;
	}

	++$i;
	my $string_end = index($message, "\0", $i) - $i;
	$self->{server_version} = substr $message, $i, $string_end;
	printf "Server Version: %s\n", $self->{server_version}
		if Net::MySQL->debug;

	$i += $string_end + 1;
	$self->{server_thread_id} = unpack 'v', substr $message, $i, 2;
	$i += 4;
	$self->{salt} = substr $message, $i, 8;
	printf "Salt: %s\n", $self->{salt} if Net::MySQL->debug;
}


sub _request_authentication
{
	my $self = shift;
	my $mysql = $self->{socket};
	$self->_send_login_message();

	my $auth_result;
	$mysql->recv($auth_result, BUFFER_LENGTH, 0);
	$self->_dump_packet($auth_result) if Net::MySQL->debug;
	if ($self->_is_error($auth_result)) {
		$mysql->close;
		if (length $auth_result < 7) {
			croak "Timeout of authentication";
		}
		croak substr $auth_result, 7;
	}
	print "connect database\n" if Net::MySQL->debug;
}


sub _send_login_message
{
	my $self = shift;
	my $mysql = $self->{socket};

	my $body = "\0\0\x01\x8d\x00\00\00\00". join "\0",
		$self->{user},
		Net::MySQL::Password->scramble(
			$self->{password}, $self->{salt}, $self->{client_capabilities}
		),
		$self->{database};
	my $login_message = chr(length($body)-3). $body;
	$mysql->send($login_message, 0);
	$self->_dump_packet($login_message) if Net::MySQL->debug;
}



sub _execute_command
{
	my $self = shift;
	my $command = shift;
	my $sql = shift;
	my $mysql = $self->{socket};

	my $message = pack('V', length($sql) + 1). $command. $sql;

	$mysql->send($message, 0);
	$self->_dump_packet($message) if Net::MySQL->debug;

	my $result;
	$mysql->recv($result, BUFFER_LENGTH, 0);
	$self->_dump_packet($result) if Net::MySQL->debug;
	$self->_reset_status;

	if ($self->_is_error($result)) {
		return $self->_set_error_by_packet($result);
	}
	elsif ($self->_is_select_query_result($result)) {
		return $self->_get_record_by_server($result);
	}
	elsif ($self->_is_update_query_result($result)){
		return $self->_get_affected_rows_information_by_packet($result);
	}
	else {
		croak 'Unknown Result: '. $self->_get_result_length($result). 'byte';
	}
}


sub _initialize
{
	my $self = shift;
	$self->_connect;
	$self->_get_server_information;
	$self->_request_authentication;
}


sub _set_error_by_packet
{
	my $self = shift;
	my $packet = shift;

	my $error_message = $self->_get_server_message($packet);
	$self->{server_message} = $error_message;
	$self->{error_code}     = $self->_get_error_code($packet);
	return undef;
}


sub _get_record_by_server
{
	my $self = shift;
	my $packet = shift;
	my $mysql = $self->{socket};

	$self->_get_column_length($packet);
	while ($self->_has_next_packet($packet)) {
		my $next_result;
		$mysql->recv($next_result, BUFFER_LENGTH, 0);
		$packet .= $next_result;
		$self->_dump_packet($next_result) if Net::MySQL->debug;
	}
	$self->{selected_record} = $packet;
}


sub _get_affected_rows_information_by_packet
{
	my $self = shift;
	my $packet = shift;

	$self->{affected_rows_length} = $self->_get_affected_rows_length($packet);
	$self->{insert_id} = $self->_get_insert_id($packet);
	$self->{server_message} = $self->_get_server_message($packet);
	return $self->{affected_rows_length};
}


sub _is_error
{
	my $self = shift;
	my $packet = shift;
	return 1 if length $packet < 4;
	ord(substr $packet, 4) == 255;
}


sub _is_select_query_result
{
	my $self = shift;
	my $packet = shift;
	return undef if $self->_is_error($packet);
	ord(substr $packet, 4) >= 1;
}


sub _is_update_query_result
{
	my $self = shift;
	my $packet = shift;
	return undef if $self->_is_error($packet);
	ord(substr $packet, 4) == 0;
}


sub _get_result_length
{
	my $self = shift;
	my $packet = shift;
	ord(substr $packet, 0, 1)
}


sub _get_column_length
{
	my $self = shift;
	my $packet = shift;
	ord(substr $packet, 4);
}


sub _get_affected_rows_length
{
	my $self = shift;
	my $packet = shift;
	ord(substr $packet, 5, 1);
}


sub _get_insert_id
{
	my $self = shift;
	my $packet = shift;
	return ord(substr $packet, 6, 1) if ord(substr $packet, 6, 1) != 0xfc;
	unpack 'v', substr $packet, 7, 2;
}


sub _get_server_message
{
	my $self = shift;
	my $packet = shift;
	return '' if length $packet < 7;
	substr $packet, 7;
}


sub _get_error_code
{
	my $self = shift;
	my $packet = shift;
	$self->_is_error($packet)
		or croak "_get_error_code(): Is not error packet";
	unpack 'v', substr $packet, 5, 2;
}


sub _reset_status
{
	my $self = shift;
	$self->{insert_id}       = 0;
	$self->{server_message}  = '';
	$self->{error_code}      = undef;
	$self->{selected_record} = undef;
}


sub _has_next_packet
{
	my $self = shift;
	substr($_[0], -1) ne "\xfe";
}


sub _dump_packet
{
	my $self = shift;
	my $packet = shift;

	my ($method_name) = (caller(1))[3];
	printf "%s():\n%s\n",
		$method_name,
		join ' ', map { sprintf "%02x", ord $_ } split //, $packet;
	printf "%s():\n%s\n",
		$method_name,
		join '  ', map { m/[\d \w\._]/ ? $_ : '.' } split //, $packet;
	print "--\n";
}



package Net::MySQL::RecordIterator;
use strict;

use constant NULL_COLUMN           => 251;
use constant UNSIGNED_CHAR_COLUMN  => 251;
use constant UNSIGNED_SHORT_COLUMN => 252;
use constant UNSIGNED_INT24_COLUMN => 253;
use constant UNSIGNED_INT32_COLUMN => 254;
use constant UNSIGNED_CHAR_LENGTH  => 1;
use constant UNSIGNED_SHORT_LENGTH => 2;
use constant UNSIGNED_INT24_LENGTH => 3;
use constant UNSIGNED_INT32_LENGTH => 4;
use constant UNSIGNED_INT32_PAD_LENGTH => 4;


sub new
{
	my $class = shift;
	my $packet = shift;
	bless {
		packet   => $packet,
		position => 0,
		column   => [],
	}, $class;
}


sub parse
{
	my $self = shift;
	$self->_get_column_length;
	$self->_get_column_name;
}


sub each
{
	my $self = shift;
	my @result;
	return undef if $self->is_end_of_packet;

	for (1..$self->{column_length}) {
		push @result, $self->_get_string_and_seek_position;
	}
	$self->{position} += 4;
	return \@result;
}


sub is_end_of_packet
{
	my $self = shift;
	length $self->{packet} <= $self->{position} + 1;
}


sub get_field_length
{
	my $self = shift;
	$self->{column_length};
}


sub get_field_names
{
	my $self = shift;
	map { $_->{column} } @{$self->{column}};
}


sub _get_column_length
{
	my $self = shift;
	$self->{position} += 4;
	$self->{column_length} = ord substr $self->{packet}, $self->{position}, 1;
	$self->{position} += 5;
	printf "Column Length: %d\n", $self->{column_length}
		if Net::MySQL->debug;
}


sub _get_column_name
{
	my $self = shift;
	for my $i (1.. $self->{column_length}) {
		push @{$self->{column}}, {
			table  => $self->_get_string_and_seek_position,
			column => $self->_get_string_and_seek_position,
		};
		$self->{position} += 14;
	}
	$self->{position} += 5;

	printf "Column name: %s\n",
		join ", ", map { $_->{column} } @{$self->{column}}
			if Net::MySQL->debug;
}


sub _get_string_and_seek_position
{
	my $self = shift;

	my $length = $self->_get_field_length();
	return undef unless defined $length;

	my $string = substr $self->{packet}, $self->{position}, $length;
	$self->{position} += $length;
	return $string;
}


sub _get_field_length
{
	my $self = shift;

	my $head = ord substr(
		$self->{packet},
		$self->{position},
		UNSIGNED_CHAR_LENGTH
	);
	$self->{position} += UNSIGNED_CHAR_LENGTH;

	return undef if $head == NULL_COLUMN;
	if ($head < UNSIGNED_CHAR_COLUMN) {
		return $head;
	}
	elsif ($head == UNSIGNED_SHORT_COLUMN) {
		warn "in short";
		my $length = unpack 'v', substr(
			$self->{packet},
			$self->{position},
			UNSIGNED_SHORT_LENGTH
		);
		$self->{position} += UNSIGNED_SHORT_LENGTH;
		return $length;
	}
	elsif ($head == UNSIGNED_INT24_COLUMN) {
		warn "in int23";
		my $int24 = substr(
			$self->{packet}, $self->{position},
			UNSIGNED_INT24_LENGTH
		);
		my $length = unpack('C', substr($int24, 0, 1))
		          + (unpack('C', substr($int24, 1, 1)) << 8)
			  + (unpack('C', substr($int24, 2, 1)) << 16);
		$self->{position} += UNSIGNED_INT24_LENGTH;
		return $length;
	}
	else {
		warn "in int32";
		my $int32 = substr(
			$self->{packet}, $self->{position},
			UNSIGNED_INT32_LENGTH
		);
		my $length = unpack('C', substr($int32, 0, 1))
		          + (unpack('C', substr($int32, 1, 1)) << 8)
			  + (unpack('C', substr($int32, 2, 1)) << 16)
			  + (unpack('C', substr($int32, 3, 1)) << 24);
		$self->{position} += UNSIGNED_INT32_LENGTH;
		$self->{position} += UNSIGNED_INT32_PAD_LENGTH;
		return $length;
	}
}


package Net::MySQL::Password;
use strict;

sub scramble
{
	my $class = shift;
	my $password = shift;
	my $hash_seed = shift;
	my $client_capabilities = shift;

	return '' unless $password;
	return '' if length $password == 0;

	my $hsl = length $hash_seed;
	my @out;
	my @hash_pass = _get_hash($password);
	my @hash_mess = _get_hash($hash_seed);

	my ($max_value, $seed, $seed2);
	my ($dRes, $dSeed, $dMax);
	if ($client_capabilities < 1) {
		$max_value = 0x01FFFFFF;
		$seed = _xor_by_long($hash_pass[0], $hash_mess[0]) % $max_value;
		$seed2 = int($seed / 2);
	} else {
		$max_value= 0x3FFFFFFF;
		$seed  = _xor_by_long($hash_pass[0], $hash_mess[0]) % $max_value;
		$seed2 = _xor_by_long($hash_pass[1], $hash_mess[1]) % $max_value;
	}
	$dMax = $max_value;

	for (my $i=0; $i < $hsl; $i++) {
		$seed  = int(($seed * 3 + $seed2) % $max_value);
		$seed2 = int(($seed + $seed2 + 33) % $max_value);
		$dSeed = $seed;
		$dRes = $dSeed / $dMax;
		push @out, int($dRes * 31) + 64;
	}

	if ($client_capabilities == 1) {
		# Make it harder to break
		$seed  = ($seed * 3 + $seed2  ) % $max_value;
		$seed2 = ($seed + $seed2 + 33 ) % $max_value;
		$dSeed = $seed;

		$dRes = $dSeed / $dMax;
		my $e = int($dRes * 31);
		for (my $i=0; $i < $hsl ; $i++) {
			$out[$i] ^= $e;
		}
	}
	return join '', map { chr $_ } @out;
}


sub _get_hash
{
	my $password = shift;

	my $nr = 1345345333;
	my $add = 7; 
	my $nr2 = 0x12345671;
	my $tmp;
	my $pwlen = length $password;
	my $c;

	for (my $i=0; $i < $pwlen; $i++) {
		my $c = substr $password, $i, 1;
		next if $c eq ' ' || $c eq "\t";
		my $tmp = ord $c;
		my $value = ((_and_by_char($nr, 63) + $add) * $tmp) + $nr * 256;
		$nr = _xor_by_long($nr, $value);
		$nr2 += _xor_by_long(($nr2 * 256), $nr);
		$add += $tmp;
	}
	return (_and_by_long($nr, 0x7fffffff), _and_by_long($nr2, 0x7fffffff));
}


sub _and_by_char
{
	my $source = shift;
	my $mask   = shift;

	return $source & $mask;
}


sub _and_by_long
{
	my $source = shift;
	my $mask = shift || 0xFFFFFFFF;

	return _cut_off_to_long($source) & _cut_off_to_long($mask);
}


sub _xor_by_long
{
	my $source = shift;
	my $mask = shift || 0;

	return _cut_off_to_long($source) ^ _cut_off_to_long($mask);
}


sub _cut_off_to_long
{
	my $source = shift;

	if ($] >= 5.006) {
		$source = $source % (0xFFFFFFFF + 1) if $source > 0xFFFFFFFF;
		return $source;
	}
	while ($source > 0xFFFFFFFF) {
		$source -= 0xFFFFFFFF + 1;
	}
	return $source;
}


1;
__END__

=head1 NAME

Net::MySQL - Pure Perl MySQL network protocol interface.

=head1 SYNOPSIS

  use Net::MySQL;
  
  my $mysql = Net::MySQL->new(
      # hostname => 'mysql.example.jp',   # Default use UNIX socket
      database => 'your_database_name',
      user     => 'user',
      password => 'password'
  );

  # INSERT example
  $mysql->query(q{
      INSERT INTO tablename (first, next) VALUES ('Hello', 'World')
  });
  printf "Affected row: %d\n", $mysql->get_affected_rows_length;

  # SLECT example
  $mysql->query(q{SELECT * FROM tablename});
  my $record_set = $mysql->create_record_iterator;
  while (my $record = $record_set->each) {
      printf "First column: %s Next column: %s\n",
          $record->[0], $record->[1];
  }
  $mysql->close;

=head1 DESCRIPTION

Net::MySQL is a Pure Perl client interface for the MySQL database. This module implements network protocol between server and client of MySQL, thus you don't need external MySQL client library like libmysqlclient for this module to work. It means this module enables you to connect to MySQL server from some operation systems which MySQL is not ported. How nifty!

Since this module's final goal is to completely replace DBD::mysql, API is made similar to that of DBI.

From perl you activate the interface with the statement

    use Net::MySQL;

After that you can connect to multiple MySQL daemon and send multiple queries to any of them via a simple object oriented interface.

There are two classes which have public APIs: Net::MySQL and Net::MySQL::RecordIterator.

    $mysql = Net::MySQL->new(
        hostname => $host,
        database => $database,
        user     => $user,
        password => $password,
    );

Once you have connected to a daemon, you can can execute SQL with:

    $mysql->query(q{
        INSERT INTO foo (id, message) VALUES (1, 'Hello World')
    });

If you want to retrieve results, you need to create a so-called statement handle with:

    $mysql->query(q{
        SELECT id, message FROM foo
    });
    if ($mysql->has_selected_record) {
        my $a_record_iterator = $mysql->create_record_iterator;
        # ...
    }

This Net::MySQL::RecordIterator object can be used for multiple purposes. First of all you can retreive a row of data:

    my $record = $a_record_iterator->each;

The each() method takes out the reference result of one line at a time, and the return value is ARRAY reference.

=head2 Net::MySQL API

=over 4

=item new(HASH)

    use Net::MySQL;
    use strict;

    my $mysql = Net::MySQL->new(
        unixsocket => $path_to_socket,
        hostname   => $host,
        database   => $database,
        user       => $user,
        password   => $password,
    );

The constructor of Net::MySQL. Connection with MySQL daemon is established and the object is returned. Argument hash contains following parameters:

=over 8

=item unixsocket

Path of the UNIX socket where MySQL daemon. default is F</tmp/mysql.sock>.
Supposing I<hostname> is omitted, it will connect by I<UNIX Socket>.

=item hostname

Name of the host where MySQL daemon runs.
Supposing I<hostname> is specified, it will connect by I<INET Socket>.

=item port

Port where MySQL daemon listens to. default is 3306.

=item database

Name of the database to connect.

=item user / password

Username and password for database authentication.

=item timeout

The waiting time which carries out a timeout when connection is overdue is specified.

=item debug

The exchanged packet will be outputted if a true value is given.

=back


=item create_database(DB_NAME)

A create_DATABASE() method creates a database by the specified name.

    $mysql->create_database('example_db');
    die $mysql->get_error_message if $mysql->is_error;

=item drop_database(DB_NAME)

A drop_database() method deletes the database of the specified name.

    $mysql->drop_database('example_db');
    die $mysql->get_error_message if $mysql->is_error;

=item query(SQL_STRING)

A query() method transmits the specified SQL string to MySQL database, and obtains the response.

=item create_record_iterator()

When SELECT type SQL is specified, Net::MySQL::RecordIterator object which shows the reference result is returned.

    $mysql->query(q{SELECT * FROM table});
    my $a_record_iterator = $mysql->create_recrod_iterator();

Net::MySQL::RecordIterator object is applicable to acquisition of a reference result. See L<"/Net::SQL::RecordIterator API"> for more.

=item get_affected_rows_length()

returns the number of records finally influenced by specified SQL.

    my $affected_rows = $mysql->get_affected_rows_length;

=item get_insert_id()

MySQL has the ability to choose unique key values automatically. If this happened, the new ID will be stored in this attribute. 

=item is_error()

TRUE will be returned if the error has occurred.

=item has_selected_record()

TRUE will be returned if it has a reference result by SELECT.

=item get_field_length()

return the number of column.

=item get_field_names()

return column names by ARRAY.

=item close()

transmits an end message to MySQL daemon, and closes a socket.

=back

=head2 Net::MySQL::RecordIterator API

Net::MySQL::RecordIterator object is generated by the query() method of Net::MySQL object. Thus it has no public constructor method.

=over 4

=item each()

each() method takes out only one line from a result, and returns it as an ARRAY reference. C<undef> is returned when all the lines has been taken out.

    while (my $record = $a_record_iterator->each) {
        printf "Column 1: %s Column 2: %s Collumn 3: %s\n",
            $record->[0], $record->[1], $record->[2];
    }

=back

=head1 SUPPORT OPERATING SYSTEM

This module has been tested on these OSes.

=over 4

=item * MacOS 9.x

with MacPerl5.6.1r.

=item * MacOS X

with perl5.6.0 build for darwin.

=item * Windows2000

with ActivePerl5.6.1 build631.

=item * FreeBSD 3.4 and 4.x

with perl5.6.1 build for i386-freebsd.

with perl5.005_03 build for i386-freebsd.

=item * Linux

with perl 5.005_03 built for ppc-linux.

with perl 5.6.0 bult for i386-linux.

=item * Solaris 2.6 (SPARC)

with perl 5.6.1 built for sun4-solaris.

with perl 5.004_04 built for sun4-solaris.

Can use on Solaris2.6 with perl5.004_04, although I<make test> is failure.

=back

This list is the environment which I can use by the test usually. Net::MySQL will operate  also in much environment which is not in a list.

I believe this module can work with whatever perls which has B<IO::Socket>. I'll be glad if you give me a report of successful installation of this module on I<rare> OSes.

=head1 SEE ALSO

L<libmysql>, L<IO::Socket>

=head1 AUTHOR

Hiroyuki OYAMA E<lt>oyama@module.jpE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002 Hiroyuki OYAMA. Japan. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
