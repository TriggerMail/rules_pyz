#!/usr/bin/env python

import tests.print_file_path

def file_path():
    return __file__

def raise_exception():
    raise Exception('test traceback')

def main():
    print('main __file__: ' + __file__)
    print('import __file__: ' + tests.print_file_path.__file__)

    tests.print_file_path.raise_exception()


if __name__ == '__main__':
    main()
