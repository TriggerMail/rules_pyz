#!/usr/bin/env python3

def main():
    bytes_string = b'bytes?'
    unicode_string = u'bytes?'
    print('bytes == unicode? %s' % (bytes_string == unicode_string))

if __name__ == '__main__':
    main()
