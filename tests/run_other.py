import os
import subprocess
import sys

RUNFILES_RELATIVE_OTHER = 'com_bluecore_rules_pyz/tests/helloworld'

def main():
    script_path = os.path.abspath(sys.argv[0])
    if '.runfiles' not in script_path:
        raise Exception('cannot find runfiles in ' + script_path)
    runfiles = script_path[:script_path.find('.runfiles')] + '.runfiles'
    server_path = os.path.join(runfiles, '__main__', 'src', 'client-site')

    print 'run_other runfiles:', runfiles
    command_path = os.path.join(runfiles, RUNFILES_RELATIVE_OTHER)
    print 'run_other command:', command_path
    output = subprocess.check_output([command_path])
    print 'run_other output:', output


if __name__ == '__main__':
    main()
