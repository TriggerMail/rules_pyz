import cStringIO
import shutil
import subprocess
import tempfile
import unittest
import zipfile


_INTERPRETER_PATH = 'tests/interpreter'
_INTERPRETER_PATH_ZIP = 'tests/interpreter_exezip'


_SCRIPT = '''
# google.cloud.datastore should be available in interpreter; as defined by BUILD deps
import google.cloud.datastore
import sys
print 'sys.argv:', repr(sys.argv)
print '__file__:', __file__
'''
class TestPyzInterpreter(unittest.TestCase):
    def run_and_expect(self, command, expect_in_output, stdin_file):
        print 'XXX', command
        output = subprocess.check_output(command, stdin=stdin_file, stderr=subprocess.STDOUT)
        self.assertIn(expect_in_output, output)
        if stdin_file is not None:
            stdin_file.seek(0)

    def run_with_args_and_expect(self, args, expect_in_output, stdin_data=None):
        '''The command should run when directly executed, with Python, or unzipped.'''

        stdin_file = None
        if stdin_data is not None:
            # can't use cStringIO: needs a .fileno
            stdin_file = tempfile.TemporaryFile()
            stdin_file.write(stdin_data)
            stdin_file.flush()
            stdin_file.seek(0)

        # execute the wrapper script
        self.run_and_expect((_INTERPRETER_PATH,) + args,
            expect_in_output, stdin_file)

        # execute the dir and __main__.py
        self.run_and_expect(('python', _INTERPRETER_PATH + '_exedir',) + args,
            expect_in_output, stdin_file)
        self.run_and_expect(('python', _INTERPRETER_PATH + '_exedir/__main__.py',) + args,
            expect_in_output, stdin_file)

        # execute the zip
        self.run_and_expect((_INTERPRETER_PATH_ZIP,) + args,
            expect_in_output, stdin_file)
        self.run_and_expect(('python', _INTERPRETER_PATH_ZIP) + args,
            expect_in_output, stdin_file)

        # unzip and execute the directory
        tempdir = tempfile.mkdtemp()
        try:
            zf = zipfile.ZipFile(_INTERPRETER_PATH_ZIP)
            zf.extractall(tempdir)

            self.run_and_expect(('python', tempdir) + args,
                expect_in_output, stdin_file)
            self.run_and_expect(('python', tempdir + '/__main__.py') + args,
                expect_in_output, stdin_file)

        finally:
            shutil.rmtree(tempdir)

    def test_interactive(self):
        # should work when directly executed, executed with Python, or unzipped
        self.run_with_args_and_expect(tuple(), '(InteractiveConsole)',
            stdin_data='import google.cloud.datastore')
   
    def test_script(self):
        script = tempfile.NamedTemporaryFile()
        script.write(_SCRIPT)
        script.flush()

        # should work when directly executed, executed with Python, or unzipped
        self.run_with_args_and_expect((script.name, 'hellomyarg'), 'hellomyarg')
