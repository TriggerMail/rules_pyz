#!/usr/bin/env python2.7
import os
import shutil
import subprocess
import sys
import tempfile


CONTAINER_IMAGE_PATH = 'pyz2_image_base/image'
DOCKER_IMAGE_TAG = 'bazel/image:image'


def main():
    if len(sys.argv) != 2:
        sys.stderr.write('usage: generate_ldconfig_cache (output ld.so.cache path)\n')
        sys.exit(1)
    output_path = sys.argv[1]

    guess_runfiles = os.path.abspath(sys.argv[0] + '.runfiles')
    # container_image script looks for this environment variable
    os.environ['PYTHON_RUNFILES'] = guess_runfiles
    container_load_path = guess_runfiles + '/' + CONTAINER_IMAGE_PATH + '/image'

    print('loading image {} ...'.format(container_load_path))
    subprocess.check_call((container_load_path, ))

    print('running docker image {} ...'.format(DOCKER_IMAGE_TAG))
    # run with a read-only root file system, write to /dev/stdout
    # ldconfig writes to a temp file then renames; use python to write it to stdout
    # this lets this work on CircleCI
    command = ('docker', 'run', '--read-only', '--interactive', '--rm',
        '--mount=type=tmpfs,destination=/tmp',
        '--entrypoint=sh', DOCKER_IMAGE_TAG, '-c',
        'ldconfig -C /tmp/out && python -c "import sys; data = open(\'/tmp/out\').read(); sys.stdout.write(data)"')
    output = subprocess.check_output(command)

    with open(output_path, 'wb') as out_file:
        out_file.write(output)


if __name__ == '__main__':
    main()
