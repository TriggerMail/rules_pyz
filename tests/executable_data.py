#!/usr/bin/env python
import os
import subprocess
import sys


def main():
    executable_path = os.path.join(os.path.dirname(__file__), 'executable.sh')
    print 'running', executable_path
    process = subprocess.Popen([executable_path])
    code = process.wait()
    print 'code', code
    sys.exit(code)


if __name__ == '__main__':
    main()
