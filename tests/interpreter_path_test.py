import unittest


_INTERPRETER_PATH_PATH = 'tests/interpreter_path'


class TestPyzInterpreterLine(unittest.TestCase):
    def test_interpreter_line(self):
        with open(_INTERPRETER_PATH_PATH) as f:
            data = f.read()
        self.assertIn('exec /usr/bin/python2.7 ', data)
