import os
import shutil
import subprocess
import tempfile
import unittest
import zipfile

_VIRTUALENV_PATH = 'tests/virtualenv'
_IMPORT_SITE_PACKAGES_PATH = 'tests/import_site_packages'


def run_output_code(args):
    process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    output = process.stdout.read()
    code = process.wait()
    return output, code

_PROTOBUF_PTH_CONTENTS = '''import sys, types, os;has_mfs = sys.version_info > (3, 5);p = os.path.join(sys._getframe(1).f_locals['sitedir'], *('google',));importlib = has_mfs and __import__('importlib.util');has_mfs and __import__('importlib.machinery');m = has_mfs and sys.modules.setdefault('google', importlib.util.module_from_spec(importlib.machinery.PathFinder.find_spec('google', [os.path.dirname(p)])));m = m or not has_mfs and sys.modules.setdefault('google', types.ModuleType('google'));mp = (m or []) and m.__dict__.setdefault('__path__',[]);(p not in mp) and mp.append(p)'''

class TestVirtualenvImports(unittest.TestCase):
    def test_site_packages_removal(self):
        self.assertTrue(os.path.exists(_VIRTUALENV_PATH))
        self.assertTrue(os.path.exists(_IMPORT_SITE_PACKAGES_PATH))

        tempdir = tempfile.mkdtemp()
        try:
            # create a virtualenv
            virtualenv_out = tempdir + '/venv'
            subprocess.check_call((_VIRTUALENV_PATH, virtualenv_out))

            # run it and make sure the command can import "wheel": included by default
            virtualenv_python = virtualenv_out + '/bin/python'
            args = (virtualenv_python, '-c', 'import wheel; print wheel.__file__')
            output = subprocess.check_output(args)
            self.assertIn('site-packages/wheel/__init__.py', output)

            # check that import google fails
            output, code = run_output_code((virtualenv_python, '-c', 'import google'))
            self.assertIn('ImportError: No module named google', output)
            self.assertEqual(1, code)

            # write the magic .pth to site-packages: makes import google work
            # this is the value shipped with the protobuf wheel
            out = virtualenv_out + '/lib/python2.7/site-packages/protobuf-3.5.0.post1-py2.7-nspkg.pth'
            with open(out, 'w') as f:
                f.write(_PROTOBUF_PTH_CONTENTS)
            output = subprocess.check_output((virtualenv_python, '-c', 'import google'))
            self.assertEqual('', output)

            # run our import test zip in this virtualenv: it should be removed
            orig_path_env = os.environ['PATH']
            os.environ['PATH'] = virtualenv_out + '/bin:' + orig_path_env
            output, code = run_output_code((_IMPORT_SITE_PACKAGES_PATH,))
            self.assertIn('ImportError: No module named wheel', output)
            self.assertIn('ImportError: No module named google', output)
            self.assertEqual(0, code)

            # run the import test zip using the virtualenv python
            os.environ['PATH'] = orig_path_env
            output, code = run_output_code((virtualenv_python, _IMPORT_SITE_PACKAGES_PATH))
            self.assertIn('ImportError: No module named wheel', output)
            self.assertIn('ImportError: No module named google', output)
            self.assertEqual(0, code)

            # unzip the thing and run it
            tempdir2 = tempfile.mkdtemp()
            try:
                zf = zipfile.ZipFile(_IMPORT_SITE_PACKAGES_PATH)
                zf.extractall(tempdir2)
                output, code = run_output_code((virtualenv_python, tempdir2))
                self.assertIn('ImportError: No module named wheel', output)
                self.assertIn('ImportError: No module named google', output)
                self.assertEqual(0, code)

            finally:
                shutil.rmtree(tempdir2)

        finally:
            shutil.rmtree(tempdir)
