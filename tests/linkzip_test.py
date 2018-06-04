import json
import os
import shutil
import subprocess
import tempfile
import unittest


# relative to runfiles
LINKZIP_PATH = 'rules_python_zip/linkzip.py'

class TestLinkZip(unittest.TestCase):
    def test_permissions(self):
        tempdir = tempfile.mkdtemp()
        try:
            file_path = tempdir + '/file'
            exe_path = tempdir + '/exe'
            open(file_path, 'w').write('hello')
            open(exe_path, 'w').write('#!/bin/sh\necho exe output\n')
            os.chmod(exe_path, 0755)

            output_path = tempdir + '/out.zip'
            manifest = dict(
                output_path=output_path,
                interpreter_path='python',
                files = [
                    dict(src=file_path, dst='file'),
                    dict(src=exe_path, dst='exe'),
                ]
            )
            manifest_file = tempfile.NamedTemporaryFile()
            json.dump(manifest, manifest_file)
            manifest_file.flush()

            subprocess.check_call((LINKZIP_PATH, manifest_file.name))

            # use the external unzip command to unzip it
            unzip_dir = tempdir + '/unzip_dir'
            os.mkdir(unzip_dir)
            # On Linux this exits with non-zero due to a warning about the header
            subprocess.call(('unzip', '-d', unzip_dir, output_path))

            # execute the exe
            out = subprocess.check_output([unzip_dir + '/exe'])
            self.assertEqual(out, 'exe output\n')

            # read the file
            data = open(unzip_dir + '/file').read()
            self.assertEqual('hello', data)
        finally:
            shutil.rmtree(tempdir)
