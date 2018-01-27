import urllib2
import unittest
import ssl

import pip._vendor.requests
import pip._vendor.requests.exceptions


BAD_URL = 'https://untrusted-root.badssl.com/'
PYPI_URL = 'https://pypi.python.org/simple/0/'


class TestSSL(unittest.TestCase):
    def test_urllib2(self):
        with self.assertRaisesRegexp(urllib2.URLError, 'certificate verify failed'):
            urllib2.urlopen(BAD_URL)

        data = urllib2.urlopen(PYPI_URL).read()
        self.assertIn('<html', data)

    def test_requests(self):
        exc_type = pip._vendor.requests.exceptions.SSLError
        with self.assertRaisesRegexp(exc_type, 'certificate verify failed'):
            pip._vendor.requests.get(BAD_URL)

        response = pip._vendor.requests.get(PYPI_URL)
        self.assertEqual(200, response.status_code)
        self.assertIn('<html', response.content)
