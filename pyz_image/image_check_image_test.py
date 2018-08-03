#!/usr/bin/env python2.7
import os
import subprocess
import sys


CONTAINER_IMAGE_PATHs = ['pyz_image/image_check_py2_image', 'pyz_image/image_check_py3_image']


def main():
    guess_runfiles = sys.argv[0] + '.runfiles'
    if os.path.exists(guess_runfiles):
        # container_image script looks for this environment variable
        guess_runfiles = os.path.abspath(guess_runfiles)
        os.environ['PYTHON_RUNFILES'] = guess_runfiles
    else:
        guess_runfiles = ''

    for container_image_path in CONTAINER_IMAGE_PATHs:
        print('testing {} ...'.format(container_image_path))

        container_path = container_image_path
        if guess_runfiles != '':
            container_path = guess_runfiles + '/com_bluecore_rules_pyz/' + container_path

        print('loading image {} ...'.format(container_path))
        sys.stdout.flush()
        subprocess.check_call((container_path, ))

        docker_tag = 'bazel/' + container_image_path.replace('/', ':')
        print('running docker image {} ...'.format(docker_tag))
        sys.stdout.flush()
        # run with a read-only root file system, but make /tmp writable
        subprocess.check_call(('docker', 'run', '--read-only', '--interactive',
            '--rm', '--tmpfs=/tmp', docker_tag))
        print('SUCCESS\n')
        sys.stderr.flush()
        sys.stdout.flush()


if __name__ == '__main__':
    main()
