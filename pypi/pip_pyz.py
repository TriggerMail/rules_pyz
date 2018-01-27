import os
import pip
import sys


def main():
    # Set PYTHONPATH to this pyz_binary's packaged root directory:
    # pip wheel executes setup.py in a subprocess that must find the bundled version of setuptools
    # without setting this variable, it ends up finding the system version
    if not os.path.exists(__file__):
        raise Exception('pip_pyz must be unzipped to work correctly')
    if sys.path[0] == '':
        raise Exception('unexpected sys.path: ' + repr(sys.path))
    os.environ['PYTHONPATH'] = sys.path[0]
    pip.main()


if __name__ == '__main__':
    main()
