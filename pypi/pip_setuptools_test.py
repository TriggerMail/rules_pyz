import os.path
import subprocess
import unittest


class TestPipSetuptools(unittest.TestCase):
    def test_setuptools(self):
        script_dir = os.path.dirname(__file__)
        pip_path = os.path.normpath(os.path.join(script_dir, 'pip'))

        cmd = (pip_path, '--no-cache-dir', '--disable-pip-version-check', '--verbose', 'wheel', '.')
        subprocess.check_call(cmd, cwd=script_dir)
        expected_path = os.path.join(script_dir, 'setuptools_wheel_test-0.1-py2-none-any.whl')
        self.assertTrue(os.path.exists(expected_path))
