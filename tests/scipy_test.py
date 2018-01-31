import scipy.optimize
import types
import unittest

class TestSciPy(unittest.TestCase):
    def test_imports(self):
        self.assertIsInstance(scipy.optimize, types.ModuleType)
