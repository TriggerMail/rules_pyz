import tests.module
import unittest

class TestModule(unittest.TestCase):
    def test_module(self):
        self.assertEqual(tests.module.one(), 1)
