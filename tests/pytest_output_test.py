#!/usr/bin/env python2.7

import os
import shutil
import subprocess
import sys
import tempfile
import xml.dom.minidom


def main():
    if len(sys.argv) != 2:
        sys.stderr.write('Error: must pass path to test binary')
    test_path = sys.argv[1]

    temp_output = tempfile.NamedTemporaryFile()
    os.environ['XML_OUTPUT_FILE'] = temp_output.name
    os.environ['SHOULD_FAIL'] = 'true'

    process = subprocess.Popen([test_path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = process.stdout.read()
    code = process.wait()
    if code != 1:
        raise Exception('unexpected code: ' + str(code))

    if '1 failed, 1 passed' not in output:
        print output
        raise Exception('unexpected output')

    # verify the XML output
    with open(temp_output.name) as f:
        data = f.read()
    parsed = xml.dom.minidom.parseString(data)
    if parsed.documentElement.getAttribute('tests') != '2':
        raise Exception('unexpected data: ' + data)
    if parsed.documentElement.getAttribute('failures') != '1':
        raise Exception('unexpected data: ' + data)

    # pytest by default caches failed tests to print "fixed" on next run:
    # not needed for Bazel, since it clears the sandbox between runs
    if os.path.exists('.cache'):
        raise Exception('pytest .cache directory was created: should not be!')
    pycache_path = os.path.join(os.path.dirname(__file__), '__pycache__')
    if os.path.exists(pycache_path):
        raise Exception('pytest __pycache__ directory was created: should not be!')

    absolute_test_path = os.path.abspath(test_path)

    # verify the test works when executed from some other directory
    tempdir = tempfile.mkdtemp()
    try:
        os.chdir(tempdir)
        del os.environ['SHOULD_FAIL']
        output = subprocess.check_output(absolute_test_path)

        if '2 passed in' not in output:
            raise Exception(output)
    finally:
        shutil.rmtree(tempdir)


if __name__ == '__main__':
    main()
