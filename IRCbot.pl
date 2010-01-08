#!/usr/bin/perl
$debug = 1;
$|++;
use LWP::Simple;
use warnings;
use POE;
use POE::Component::IRC;
use POE::Filter::Reference;
use POE::Component::Server::TCP;

#A correct TCP command will look like
#$tcp_pass irc.freenode.net&#perl&What up kids!

my $tcp_pass = "simpw";
my $tcp_port = 13337;
my $mynick = "Masonrey";

%chans = (
    'irc.freenode.net' => "\#devmason",
);

for $key ( keys %chans ) {
    print "Making connection to $key\n" if $debug;
    POE::Component::IRC->new($key) or print "Error making connection: $key\n";
    POE::Session->create(
        inline_states => {
            _start           => \&bot_start,
            irc_001          => \&on_connect,
            irc_public       => \&on_public,
            irc_disconnected => \&bot_connect,
            irc_join         => \&on_join,
            irc_msg          => \&on_msg,
            irc_kick         => \&on_kick
        },
        args => [$key],
    );
}

sub bot_start {
    my ( $kernel, $session, $heap, $sender, $server ) =
      @_[ KERNEL, SESSION, HEAP, SENDER, ARG0 ];
    print "$server : server\n" if $debug;
    my $sessid = $kernel->ID;
    $kernel->post( $server => register => "all" ) or print "post failed: $!\n";
    $kernel->post(
        $server => connect => {
            Nick     => "$mynick",
            Username => "$mynick",
            Ircname  => '#Outworld -=Outworld=-',
            Server   => "$server",

            #            Port     => '6667',
        }
    ) or print "post failed: $!\n";
    $heap->{$sessid} = $server;
}

sub on_connect {
    my ( $kernel, $sender, $heap ) = @_[ KERNEL, SENDER, HEAP ];
    my $sessid = $kernel->ID;
    my $server = $heap->{$sessid};
    print "Connected! : $server\n" if $debug;
    $channelsonserver = $chans{$server};
    if ( $channelsonserver =~ /,/ ) {
        @channels = split( ',', $channelsonserver );
        print "split [$channelsonserver] to [@channels]\n" if $debug;
    }
    else {
        @channels = $channelsonserver;
    }
    foreach $chan (@channels) {
        $kernel->post( $sender => join => $chan );
        print "Joining $chan on $server\n" if $debug;
    }
    $kernel->post( $sender => privmsg => Nickserv => "identify IRCbot" );
}

sub on_kick {
    my ( $kernel, $who, $chan, $whokick, $sender, $heap ) =
      @_[ KERNEL, ARG0, ARG1, ARG2, SENDER, HEAP ];
    my $sessid = $kernel->ID;
    my $server = $heap->{$sessid};
    if ( $whokick eq "$mynick" ) {
        print "Rejoining $chan on $server\n";
        eval { $kernel->post( $sender => join => $chan ); };
    }
}

sub on_msg {
    my ( $kernel, $who, $msg, $sender ) = @_[ KERNEL, ARG0, ARG2, SENDER ];

    my %help = (
        uptime => "Returns the uptime of the computer the bot is running on",
    );
    @topics = keys %help;
    my $nick = ( split /!/, $who )[0];
    @MSG = split( ' ', $msg );
    $topic = $MSG[1];
    if ( $msg =~ /^help/ && $topic ) {
        eval { $kernel->post( $sender => privmsg => $nick, $help{"$topic"} ); };
    }
    else {
        $kernel->post(
            $sender => privmsg => $nick,
            "Please select one of the following topics: @topics, ex. help $topics[0]"
        );
    }
}

sub on_join {
    my ( $kernel, $who, $where, $sender, $heap ) =
      @_[ KERNEL, ARG0, ARG1, SENDER, HEAP ];

    my $sessid = $kernel->ID;
    my $server = $heap->{$sessid};
    my $nick   = ( split /!/, $who )[0];
    $kernel->post( $sender => mode => @$where, "+v $nick" );
    $date = localtime;
    $where =~ s/\#//g;

}

sub on_public {
    my ( $kernel, $who, $where, $msg, $sender, $heap ) =
      @_[ KERNEL, ARG0, ARG1, ARG2, SENDER, HEAP ];
    my $sessid = $kernel->ID;
    my $server = $heap->{$sessid};
    my $nick   = ( split /!/, $who )[0];
    $date = localtime;
    @MSG = split( ' ', $msg );
    $msg =~ s/"/`/g;
    $msg =~ s/'/`/g;

    # UPTIME COMMAND
    if ( $msg =~ /uptime/ ) {
        $uptime = `uptime`;
        $kernel->post( $sender => privmsg => @$where, $uptime );
        print $uptime;
    }

    #HELP COMMAND
    elsif ( $msg =~ /^help/ ) {
        $kernel->post(
            $sender => privmsg => $nick,
            "help is active in PMs...type help"
        );
    }

    #END HELP

    #REPORTER
    elsif ( $msg =~ /^Reporter/ ) {
        $kernel->post( $sender => privmsg => @$where, "I fucking rule" );
    }

    #END REPORTER

    #KICK COMMAND
    elsif ( $msg =~ /^kick/ && lc($nick) =~ /forsaken/ ) {

        eval {
            $kernel->post(
                $sender => kick => @$where,
                $un, "Goodbye says $who"
            );
        };
    }

    #END KICK

    #END STAT
    #OP COMMAND
    elsif ( $msg =~ /^op / && lc($nick) =~ /forsaken/ ) {
        $un = $MSG[1];
        $kernel->post( $sender => mode => @$where, "+o $un" );
    }

    #END OP

    #MODE COMMAND
    elsif ( $msg =~ /^mode / && lc($nick) =~ /forsaken/ ) {
        @mode = @MSG[ 1 .. $#MSG ];
        $kernel->post( $sender => mode => @$where, "@mode" );
    }

    #END MODE
    else {
        $msg   = "($date) \($nick\) $msg\n";
        $where = $where->[0];
        $where =~ s/\#//g;
        $msg   =~ s/\#//g;

    }
}    #end of on_public

#What is done when the bot gets disconnected

sub bot_connect {
    my ( $kernel, $who, $where, $msg, $sender, $heap ) =
      @_[ KERNEL, ARG0, ARG1, ARG2, SENDER, HEAP ];
    my $sessid = $kernel->ID;
    my $server = $heap->{$sessid};
    $kernel->post(
        $server => connect => {
            Nick     => '$mynick',
            Username => 'Outworld',
            Ircname  => '#Outworld -=Outworld=-',
            Server   => "$server",
            Port     => '6667',
        }
    );
}    #end disconnected sub

POE::Component::Server::TCP->new(
    Alias       => "IRC Relay",
    Address     => "174.143.158.126", #Bind locally for "security"
    Port        => $tcp_port,
    ClientInput => sub {
        my ( $kernel, $session, $heap, $input, $sender ) =
          @_[ KERNEL, SESSION, HEAP, ARG0, SENDER ];
        my $pw = substr( $input, 0, length($tcp_pass) );
        if ( $pw eq $tcp_pass ) {
            $input =~ s/$tcp_pass\ //;
            @BOB = split( '&', $input );
            ( $srvr, $channel, $msg ) = ( $BOB[0], $BOB[1], $BOB[2] );
            $kernel->post( $srvr => privmsg => $channel, $msg )
              or print "Error sending msg to IRC: $!\n";
            print "Sent \'$msg\' to $channel on $srvr\n";
        }

    }
);
$poe_kernel->run();
exit 0;
