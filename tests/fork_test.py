import os
import sys
import tests.coding

# pytest catches sys.exit from forked children and reports failure: use a standalone process
def main():
    # file should exist before and after the fork: previously atexit would clean up
    # the temporary dir in the child
    assert os.path.exists(tests.coding.__file__)

    pid = os.fork()
    if pid == 0:
        sys.exit(42)

    _, status_code = os.waitpid(pid, 0)
    assert os.WIFEXITED(status_code)
    assert os.WEXITSTATUS(status_code) == 42

    assert os.path.exists(tests.coding.__file__)


if __name__ == '__main__':
    main()
