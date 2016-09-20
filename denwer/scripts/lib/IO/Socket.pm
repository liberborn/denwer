package IO::Socket;
use Tools;

my $cnt = 0;

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	$self->{socket} = "IO_SOCKET_" . ($cnt++);
    socket($self->{socket}, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or return;
    connect($self->{socket}, pack_sockaddr_in($args{PeerPort}, inet_aton($args{PeerAddr}))) or return;
    return $self;
}

sub send {
	my ($self, $msg, $flags) = @_;
	return send($self->{socket}, $msg, $flags || 0);
}

sub recv {
	local ($self, *buf, $len, $flags) = ($_[0], \$_[1], $_[2]);
	return recv($self->{socket}, $buf, $len, $flags || 0);
}

sub close {
	my ($self) = @_;
	close($self->{socket});
}

sub autoflush {
	my ($self, $flag) = @_;
    my $oldfh = select($self->{socket});
    $| = $flag;
    select($oldfh);
}


package IO::Socket::INET;

@ISA = 'IO::Socket';


return 1;