import certifi
import os.path
import unittest

class CertifiPathTest(unittest.TestCase):
    def test_path(self):
        path = certifi.where()
        self.assertTrue(os.path.exists(path))