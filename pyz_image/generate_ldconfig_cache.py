#!/usr/bin/env python2.7
import os
import shutil
import subprocess
import sys
import tempfile


CONTAINER_IMAGE_PATH = 'pyz_image/py2_image_base'


def main():
    if len(sys.argv) != 2:
        sys.stderr.write('usage: generate_ldconfig_cache (output ld.so.cache path)\n')
        sys.exit(1)
    output_path = sys.argv[1]

    guess_runfiles = sys.argv[0] + '.runfiles'
    container_path = CONTAINER_IMAGE_PATH
    if os.path.exists(guess_runfiles):
        # container_image script looks for this environment variable
        guess_runfiles = os.path.abspath(guess_runfiles)
        os.environ['PYTHON_RUNFILES'] = guess_runfiles
        container_path = guess_runfiles + '/com_bluecore_rules_pyz/' + container_path

    print('loading image {} ...'.format(container_path))
    subprocess.check_call((container_path, ))

    docker_tag = 'bazel/' + CONTAINER_IMAGE_PATH.replace('/', ':')
    print('running docker image {} ...'.format(docker_tag))
    # run with a read-only root file system, write to /dev/stdout
    # ldconfig writes to a temp file then renames; use python to write it to stdout
    # this lets this work on CircleCI
    command = ('docker', 'run', '--read-only', '--interactive', '--rm',
        '--mount=type=tmpfs,destination=/tmp',
        '--entrypoint=sh', docker_tag, '-c',
        'ldconfig -C /tmp/out && python -c "import sys; data = open(\'/tmp/out\').read(); sys.stdout.write(data)"')
    output = subprocess.check_output(command)

    with open(output_path, 'wb') as out_file:
        out_file.write(output)


if __name__ == '__main__':
    main()
