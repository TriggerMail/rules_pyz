import os
import subprocess
import sys


SCRIPT_RELATIVE_HELLOWORLD = os.path.join(os.path.dirname(__file__), 'helloworld')

def main():
    print 'run_other command:', SCRIPT_RELATIVE_HELLOWORLD
    output = subprocess.check_output([SCRIPT_RELATIVE_HELLOWORLD])
    print 'run_other output:', output


if __name__ == '__main__':
    main()
