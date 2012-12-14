use strict;
use Test::More;
use Test::SharedFork;
use File::Temp;

BEGIN {
    use_ok "ZMQ::LibZMQ2";
    use_ok "ZMQ::Constants", ":v2.1.11", qw(ZMQ_REP ZMQ_REQ);
}

my $path = File::Temp->new(UNLINK => 0);
my $pid = Test::SharedFork->fork();
if ($pid == 0) {
    sleep 1; # hmmm, not a good way to do this...
    my $ctxt = zmq_init();
    my $child = zmq_socket($ctxt, ZMQ_REQ );
    zmq_connect( $child, "ipc://$path" );
    zmq_send( $child, "Hello from $$" );
    exit 0;
} elsif ($pid) {
    my $ctxt = zmq_init();
    my $parent_sock = zmq_socket( $ctxt, ZMQ_REP);
    zmq_bind( $parent_sock, "ipc://$path" );
    my $msg = zmq_recv( $parent_sock );
    my $data = zmq_msg_data($msg);
    if (! is $data, "Hello from $pid", "message is the expected message") {
        diag "got '$data', expected 'Hello from $pid'";
    }
    waitpid $pid, 0;
} else {
    die "Could not fork: $!";
}

unlink $path;

done_testing;
