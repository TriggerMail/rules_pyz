import os.path
import tests.coding  # this import is the real test
import unittest

class TestImport(unittest.TestCase):
    def test_import(self):
        self.assertTrue(os.path.exists(tests.coding.__file__))
