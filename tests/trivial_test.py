import os
import unittest

class TwoTests(unittest.TestCase):
    def test_one(self):
        pass
    def test_two(self):
        if 'SHOULD_FAIL' in os.environ:
            self.fail('SHOULD_FAIL environment variable set')
        pass
