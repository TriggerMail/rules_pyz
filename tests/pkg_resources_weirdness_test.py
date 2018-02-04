import os
import shutil
import subprocess
import tempfile
import unittest

PKG_WEIRDNESS_PATH = 'tests/pkg_resources_weirdness'

class TestPkgResourcesWeirdness(unittest.TestCase):
	def test_import(self):
		# copy the pkg_weirdness binary: it needs to be a real file, not a symlink
		temp = tempfile.NamedTemporaryFile(delete=False)
		try:
			temp.close()
			shutil.copyfile(PKG_WEIRDNESS_PATH, temp.name)
			os.chmod(temp.name, 0700)
			os.chdir(os.path.dirname(temp.name))
			output = subprocess.check_output("./"+ os.path.basename(temp.name))
			self.assertIn('SUCCESS', output)
		finally:
			os.unlink(temp.name)
