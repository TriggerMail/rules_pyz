import os
import subprocess
import sys


def print_env():
    for key, value in os.environ.items():
        print('{}={}'.format(key, value))


def exec_self(path_to_execute):
    # Execute ourselves with an environment variable set: this should be passed through
    # Previously we stripped all PYTHON* environment variables which broke this
    env = dict(os.environ)
    env['PYTHON_EXAMPLE'] = 'should be found'
    args = [path_to_execute, 'print_env']
    print('executing', args)
    subprocess.check_call(args, env=env)
    print 'DONE'


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.stderr.write('Usage: python_envvars.py (path to execute)\n')
        sys.exit(1)

    if sys.argv[1] == 'print_env':
        print_env()
    else:
        exec_self(sys.argv[1])
