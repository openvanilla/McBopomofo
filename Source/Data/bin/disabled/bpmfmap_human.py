#!/usr/bin/env python
#encoding:UTF-8
import locale
import termios, fcntl, sys, os
locale.setlocale(locale.LC_ALL, '')
code = locale.getpreferredencoding()
fd = sys.stdin.fileno()

oldterm = termios.tcgetattr(fd)
newattr = termios.tcgetattr(fd)
newattr[3] = newattr[3] & ~termios.ICANON & ~termios.ECHO
termios.tcsetattr(fd, termios.TCSANOW, newattr)

oldflags = fcntl.fcntl(fd, fcntl.F_GETFL)
fcntl.fcntl(fd, fcntl.F_SETFL, oldflags | os.O_NONBLOCK)

prev_c=''
buffer=""
convertedkey=""
f1 = open('test.txt', 'r')
#f2 = open('test.tmp', 'w')
try:
    myline = f1.readline()
    while myline != '':
        returned=0
        sys.stdout.write(myline.rstrip()+' ')
        while returned==0:
            try:
                c = sys.stdin.read(1)
                if   c == '\x04': break
                elif c == '\x08' and buffer != '':
                     for i in range(len(prev_c)):
                         sys.stdout.write("[D[K")
                     buffer=buffer[:len(buffer)-len()]
                     #sys.stdout.write(buffer)
                elif c == ' ' and buffer != '':
                     buffer = buffer+' '
                     sys.stdout.write(' ')
                elif c == '\n' and convertedkey != '':
                     print
                     returned=1
                     print buffer
                     break
                elif prev_c == c: continue
                else:
                     if c == '1':
                          convertedkey=u"ㄅ"
                     elif c == 'q':
                          convertedkey=u"ㄆ"
                     elif c == 'a':
                          convertedkey=u"ㄇ"
                     elif c == 'z':
                          convertedkey=u"ㄈ"
                     elif c == '2':
                          convertedkey=u"ㄉ"
                     elif c == 'w':
                          convertedkey=u"ㄊ"
                     elif c == 's':
                          convertedkey=u"ㄋ"
                     elif c == 'x':
                          convertedkey=u"ㄌ"
                     elif c == 'e':
                          convertedkey=u"ㄍ"
                     elif c == 'd':
                          convertedkey=u"ㄎ"
                     elif c == 'c':
                          convertedkey=u"ㄏ"
                     elif c == 'r':
                          convertedkey=u"ㄐ"
                     elif c == 'f':
                          convertedkey=u"ㄑ"
                     elif c == 'v':
                          convertedkey=u"ㄒ"
                     elif c == '5':
                          convertedkey=u"ㄓ"
                     elif c == 't':
                          convertedkey=u"ㄔ"
                     elif c == 'g':
                          convertedkey=u"ㄕ"
                     elif c == 'b':
                          convertedkey=u"ㄖ"
                     elif c == 'y':
                          convertedkey=u"ㄗ"
                     elif c == 'h':
                          convertedkey=u"ㄘ"
                     elif c == 'n':
                          convertedkey=u"ㄙ"
                     elif c == 'u':
                          convertedkey=u"ㄧ"
                     elif c == 'j':
                          convertedkey=u"ㄨ"
                     elif c == 'm':
                          convertedkey=u"ㄩ"
                     elif c == '8':
                          convertedkey=u"ㄚ"
                     elif c == 'i':
                          convertedkey=u"ㄛ"
                     elif c == 'k':
                          convertedkey=u"ㄜ"
                     elif c == ',':
                          convertedkey=u"ㄝ"
                     elif c == '9':
                          convertedkey=u"ㄞ"
                     elif c == 'o':
                          convertedkey=u"ㄟ"
                     elif c == 'l':
                          convertedkey=u"ㄠ"
                     elif c == '.':
                          convertedkey=u"ㄡ"
                     elif c == '0':
                          convertedkey=u"ㄢ"
                     elif c == 'p':
                          convertedkey=u"ㄣ"
                     elif c == ';':
                          convertedkey=u"ㄤ"
                     elif c == '/':
                          convertedkey=u"ㄥ"
                     elif c == '-':
                          convertedkey=u"ㄦ"
                     elif c == '6':
                          convertedkey=u"ˊ"
                     elif c == '3':
                          convertedkey=u"ˇ"
                     elif c == '4':
                          convertedkey=u"ˋ"
                     elif c == '7':
                          convertedkey=u"˙"
                     else:
                          print "Got character", repr(c)
                          break
                     prev_c = c
                     #if buffer != '':
                        #for i in range(len(buffer)):
                        #    sys.stdout.write("[D")
                     buffer=buffer+convertedkey
                     sys.stdout.write(convertedkey)
                     print len(convertedkey)
            except IOError: pass
        myline = f1.readline()
finally:     
    termios.tcsetattr(fd, termios.TCSAFLUSH, oldterm)
    fcntl.fcntl(fd, fcntl.F_SETFL, oldflags)
f1.close
