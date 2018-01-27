#!/usr/bin/env python2.7

import argparse
import shutil
import subprocess
import sys
import tempfile
import zipfile


def run_and_check(args, expected_output, expect_success):
    proc = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = proc.stdout.read()
    returncode = proc.wait()

    print 'Exited with code %d; Output:' % (returncode)
    print output

    if expect_success:
        if returncode != 0:
            raise Exception('Failed: Expected success but exited with code: %d' % (returncode))
    elif returncode == 0:
        raise Exception('Failed: Expected failure but exited with code: %d' % (returncode))

    if expected_output not in output:
        raise Exception('Expected output "%s" not found' % (expected_output))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--command', required=True, help='command to execute')
    parser.add_argument('--expected-output', required=True,
        help='string that must exist in the output')
    parser.add_argument('--no-unzip', action='store_true',
        help='do not unzip and execute as a directory')
    parser.add_argument('--expect-failure', action='store_true',
        help='the command should exit with a code other than 0')
    args = parser.parse_args()

    command_path = args.command
    expected_output = args.expected_output
    expect_success = not args.expect_failure

    run_and_check([command_path], expected_output, expect_success)

    # unpack the zip and try it again: it should work
    if not args.no_unzip:
        print 'testing from unpacked zip ...'
        tempdir = tempfile.mkdtemp()
        try:
            zf = zipfile.ZipFile(command_path)
            zf.extractall(tempdir)
            zf.close()

            run_and_check(['python2.7', tempdir], expected_output, expect_success)
        finally:
            shutil.rmtree(tempdir)

    # with some crazy import/path manipulation, running python directly can screw up
    print 'testing explicitly executing with python2.7 ...'
    run_and_check(['python2.7', command_path], expected_output, expect_success)

    print 'PASS'


if __name__ == '__main__':
    main()
