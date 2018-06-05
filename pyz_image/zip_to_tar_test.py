import unittest
import zip_to_tar
import tempfile
import zipfile
import tarfile

class TestZipToTar(unittest.TestCase):
    def test_tool(self):
        temp_zip = tempfile.NamedTemporaryFile()
        temp_tar = tempfile.NamedTemporaryFile()

        with zipfile.ZipFile(temp_zip, 'w') as zf:
            zf.writestr('hello', 'contents')
        temp_zip.flush()

        zip_to_tar.zip_to_tar(temp_zip.name, temp_tar.name, 'prefix')

        names = []
        with tarfile.open(temp_tar.name) as tf:
            for tarinfo in tf:
                names.append(tarinfo.name)
        self.assertEqual(['prefix/hello'], names)



