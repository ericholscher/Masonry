use Net::Telnet ();
$srv = "irc.freenode.net";
$chan = "\#devmason";
$pw = "example_pw";
@msg = @ARGV;
$pop = new Net::Telnet( Telnetmode => 0 );
if ( $pop->open( Host => localhost, Port => 13337 ) ) {
    $pop->print("$pw $srv&$chan&@msg\n");
    $date = localtime;
    $msg  = "($date) \(Me\) @msg";
}
else {
    print "Bot is not running, sorry, these things happen<br>\n";
}
print "$username - $srv - $chan: $msg\n" or print "err: $!";


