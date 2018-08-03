#!/usr/bin/env python2.7
import ctypes.util
import os
import sys
import traceback
try:
    # python2
    import urllib2
    _urlopen = urllib2.urlopen
except ImportError:
    import urllib.request
    _urlopen = urllib.request.urlopen


def check_ssl_root_certificates():
    # distroless had a broken OpenSSL configuration:
    # https://github.com/GoogleContainerTools/distroless/issues/155
    # rules_docker has been slow to pick it up:
    # https://github.com/bazelbuild/rules_docker/issues/477

    print('fetching https://www.google.com/ ...')
    # this fails if the certificate cannot be verified
    fh = _urlopen('https://www.google.com/')
    try:
        print('code: {}'.format(fh.code))
        if fh.code != 200:
            raise Exception('unexpected code: %d' % (fh.code))
    finally:
        fh.close()


def check_system():
    print('executing {} using os.system'.format(sys.executable))
    code = os.system('{} -c ""'.format(sys.executable))
    if code != 0:
        raise Exception('expected exit code 0; got %d' % (code))


def check_find_library():
    # From https://github.com/benoitc/gunicorn/blob/master/gunicorn/http/_sendfile.py
    # See https://github.com/GoogleContainerTools/distroless/issues/150
    libc = ctypes.CDLL(ctypes.util.find_library("c"), use_errno=True)
    sendfile = libc.sendfile
    if sendfile is None:
        raise Exception('sendfile should exist in libc')

    # From https://github.com/atdt/monotonic/blob/master/monotonic.py
    # This is finding a function which is shipped with the linux C library
    librt = ctypes.CDLL(ctypes.util.find_library('rt'), use_errno=True)
    print(dir(librt))
    print(librt)
    # distroless python3 find_library("...") returns None if the required tools don't exist
    # ctypes.CDLL(None) loads symbols from the current process, which "works" but only because
    # clock_gettime is in libc for glibc >= 2.17; timer_gettime is not
    timer_gettime = librt.timer_gettime
    if timer_gettime is None:
        raise Exception('timer_gettime should exist in librt as part of glibc')


def main():
    checks = []
    for symbol, value in globals().items():
        if symbol.startswith('check_'):
            checks.append((symbol, value))
    checks.sort()

    failed = 0
    passed = 0
    for check_name, check_func in checks:
        print('running %s:' % (check_name))
        sys.stdout.flush()
        try:
            check_func()
            print('PASSED\n')
            passed += 1
        except Exception as e:
            print('FAILED:\n')
            traceback.print_exc(file=sys.stdout)
            print('')
            failed += 1

    print('{} passed / {} total'.format(passed, passed + failed))
    if failed > 0:
        sys.exit(1)


if __name__ == '__main__':
    main()
