import os
import subprocess
import unittest
import tempfile
import shutil
import zipfile
import sys


# relative to RUNFILES/workspace as specified by:
# https://docs.bazel.build/versions/master/test-encyclopedia.html
BUILT_PATH = 'tests/print_file_path'
BUILT_PATH_FORCE_ALL_UNZIP = BUILT_PATH + '_force_all_unzip'

class TestPrintFilePath(unittest.TestCase):
    def run_output_code(self, command):
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        output = process.stdout.read()
        code = process.wait()
        return output, code

    def run_and_check_regexps(self, command, regexps):
        output, code = self.run_output_code(command)
        print output

        for regexp in regexps:
            self.assertRegexpMatches(output, regexp)
        self.assertEqual(1, code)

    def test_execute_script(self):
        regexps = [
            '^main __file__: .+/print_file_path_exedir/tests/print_file_path.py',
            '\nimport __file__: .+/print_file_path_exedir/tests/print_file_path.py',
        ]
        # run the script directly
        self.run_and_check_regexps((BUILT_PATH,), regexps)
        # run the exedir
        self.run_and_check_regexps(('python', BUILT_PATH + '_exedir',), regexps)
        # run exedir/__main__.py
        self.run_and_check_regexps(('python', BUILT_PATH + '_exedir/__main__.py',), regexps)

    # TODO: Re-enable!
    # def test_execute_zipped(self):
    #     regexps = [
    #         '^main __file__: .+/print_file_path/tests/print_file_path.py',
    #         '\nimport __file__: .+/print_file_path/tests/print_file_path.py',
    #     ]
    #     self.run_and_check_regexps((BUILT_PATH,), regexps)

    # def test_execute_zipped_force_unzip(self):
    #     regexps = [
    #         '^main __file__: .+_pyzip/tests/print_file_path.py',
    #         '\nimport __file__: .+_pyzip/tests/print_file_path.py',
    #         # traceback has code!
    #         '\n    raise Exception'
    #     ]
    #     self.run_and_check_regexps((BUILT_PATH_FORCE_ALL_UNZIP,), regexps)

    # def test_execute_unzipped(self):
    #     tempdir = tempfile.mkdtemp()
    #     try:
    #         zf = zipfile.ZipFile(BUILT_PATH)
    #         extract_dir = tempdir+'/dir'
    #         zf.extractall(extract_dir)

    #         regexps = [
    #             '^main __file__: .+/dir/tests/print_file_path.py',
    #             '\nimport __file__: .+/dir/tests/print_file_path.py',
    #             # traceback has code!
    #             '\n    raise Exception'
    #         ]
    #         self.run_and_check_regexps(('python', extract_dir), regexps)

    #         # run without our magic __main__ wrapper: "normal" Python
    #         os.chdir(extract_dir)
    #         os.environ['PYTHONPATH'] = '.'
    #         regexps = [
    #             # main is relative; Python makes the import absolute
    #             '^main __file__: tests/print_file_path.py',
    #             '\nimport __file__: .+/dir/tests/print_file_path.py'
    #         ]
    #         self.run_and_check_regexps(('python', 'tests/print_file_path.py'), regexps)

    #     finally:
    #         shutil.rmtree(tempdir)
