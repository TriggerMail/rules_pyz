#!/usr/bin/env python
'''
Verifies that the checked in ld.so.cache matches the generated file from
the current base image. This avoids a circular dependency, and means users
don't need docker to build images. You do need docker to test this.
'''

import sys

CHECKED_IN_PATH = 'pyz_image/ld.so.cache'
GENERATED_PATH = 'pyz_image/ld.so.cache.new'

def main():
    checked_in = open(CHECKED_IN_PATH).read()
    generated = open(GENERATED_PATH).read()
    if checked_in != generated:
        sys.stderr.write('Error: checked in file {} does not match generated file {}\n'.format(
            CHECKED_IN_PATH, GENERATED_PATH))
        sys.exit(1)


if __name__ == '__main__':
    main()
