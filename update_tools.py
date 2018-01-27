#!/usr/bin/env python

import os
import subprocess

GOOS_TO_BAZEL = {
    'darwin': 'osx',
    'linux': 'linux',
}

GO_TOOL_SRC = ('rules_python_zip/simplepack.go', 'pypi/pip_generate.go')

# TODO: Build 32-bit versions?
GOARCH='amd64'


def main():
    script_dir = os.path.dirname(__file__)

    for src in GO_TOOL_SRC:
        for goos, bazel_os in GOOS_TO_BAZEL.iteritems():
            tool_name = os.path.splitext(os.path.basename(src))[0]
            output = os.path.join(script_dir, 'tools', '%s-x64-%s' % (tool_name, bazel_os))
            env = dict(os.environ)
            env['GOOS'] = goos
            env['GOARCH'] = GOARCH
            command = ('go', 'build', '-o', output, src)
            subprocess.check_call(command, env=env)
            print(output)


if __name__ == '__main__':
    main()
