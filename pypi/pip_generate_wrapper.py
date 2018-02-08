#!/usr/bin/env python

import glob
import os
import sys

# Bazel paths relative to this file
PIP_RELATIVE_PATH = 'pip'
PIP_GENERATE_RELATIVE_GLOB = '../tools/pip_generate*'
WHEEL_TOOL_RELATIVE_PATH = 'wheeltool'


def resolve_script_relative_path(relative_path):
    file_dir = os.path.dirname(__file__)
    return os.path.normpath(os.path.join(file_dir, relative_path))


def main():
    resolved_glob = resolve_script_relative_path(PIP_GENERATE_RELATIVE_GLOB)
    pip_generate_path = glob.glob(resolved_glob)[0]
    wheel_tool_path = resolve_script_relative_path(WHEEL_TOOL_RELATIVE_PATH)
    if not os.path.exists(pip_generate_path):
        sys.stderr.write('Error: could not find pip_generate\n')
        sys.exit(1)
    if not os.path.exists(wheel_tool_path):
        sys.stderr.write('Error: could not find wheeltool\n')
        sys.exit(1)

    pip_dir = os.path.dirname(resolve_script_relative_path(PIP_RELATIVE_PATH))
    os.environ['PATH'] = pip_dir + ':' + os.environ['PATH']
    command = [pip_generate_path, "--wheelToolPath=" + wheel_tool_path] + sys.argv[1:]
    os.execv(command[0], command)


if __name__ == '__main__':
    main()
