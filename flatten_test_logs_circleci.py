#!/usr/bin/env python
# bazel-testlogs contains test.xml in deeply nested directories
# CircleCI wants only 1 level of directories
import os
import shutil
import sys

def main():
    if len(sys.argv) != 3:
        sys.stderr.write('Usage: flatten_test_logs_circleci.py (bazel-testlogs) (output dir)\n')
        sys.exit(1)

    testlogs_path = sys.argv[1]
    output_dir = sys.argv[2]

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

    for dirpath, dirnames, filenames in os.walk(testlogs_path):
        for filename in filenames:
            if filename.endswith('.xml'):
                orig_path = os.path.join(dirpath, filename)
                assert orig_path.startswith(testlogs_path + '/')
                truncated_path = orig_path[len(testlogs_path)+1:]

                dest_path = os.path.join(output_dir, truncated_path.replace('/', '_'))
                print '%s -> %s' % (orig_path, dest_path)
                shutil.copyfile(orig_path, dest_path)


if __name__ == '__main__':
    main()
