import py.path
import unittest
import types

class TestWheelImport(unittest.TestCase):
    def test_wheel_import(self):
        self.assertIsInstance(py.path, types.ModuleType)
