#!/usr/bin/env python2.7
import tests.helloworld

def main():
    print 'hello_import:'
    tests.helloworld.main()
    print 'hello_import done'


if __name__ == '__main__':
    main()
