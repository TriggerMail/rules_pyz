#!/usr/bin/env python2.7
import os
import shutil
import subprocess
import sys
import tempfile


CONTAINER_IMAGE_PATH = 'pyz_image/py2_base_image'


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

    # create a temporary directory to store the output
    tempdir = tempfile.mkdtemp()
    try:
        docker_tag = 'bazel/' + CONTAINER_IMAGE_PATH.replace('/', ':')
        print('running docker image {} ...'.format(docker_tag))
        # run with a read-only root file system, write to /output
        subprocess.check_call(('docker', 'run', '--read-only', '--interactive', '--rm',
            '--mount=type=bind,source={},destination=/output'.format(tempdir),
            '--entrypoint=/sbin/ldconfig', docker_tag, '-C', '/output/ld.so.cache'))

        shutil.copyfile(tempdir + '/ld.so.cache', output_path)
    finally:
        shutil.rmtree(tempdir)


if __name__ == '__main__':
    main()
