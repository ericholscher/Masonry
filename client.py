import telnetlib
import sys

pw = "example_pw"
srv = "irc.freenode.net"
chan = "#devmason"

t = telnetlib.Telnet()
t.open('localhost', port=13337)
t.write('%s %s&%s&%s\n' % (pw, srv, chan,' '.join(sys.argv[1:])))

