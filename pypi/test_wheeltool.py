from pkg_resources._vendor.packaging import markers
import tempfile
import unittest
import wheeltool
import zipfile

class TestWheelTool(unittest.TestCase):
    def _parse_metadata(self, package_and_version, contents):
        self.temp = tempfile.NamedTemporaryFile(prefix=package_and_version + '-py2.py3-none-any.whl')
        zip_out = zipfile.ZipFile(self.temp, 'w')
        zip_out.writestr(package_and_version + '.dist-info/METADATA', contents)
        zip_out.close()
        self.temp.flush()
        return wheeltool.Wheel(self.temp.name)

    def test_tenacity_metadata(self):
        wheel = self._parse_metadata('tenacity-4.10.0', _TENACITY_METADATA)
        self.assertEqual('tenacity', wheel.distribution())
        self.assertEqual('4.10.0', wheel.version())
        self.assertEqual(['six', 'futures', 'monotonic'], list(wheel.dependencies()))
        self.assertEqual([], wheel.extras())

    def test_wheel_metadata(self):
        wheel = self._parse_metadata('wheel-0.31.0', _WHEEL_METADATA)
        self.assertEqual('wheel', wheel.distribution())
        self.assertEqual('0.31.0', wheel.version())
        self.assertEqual([], list(wheel.dependencies()))
        self.assertEqual(['test', 'signatures', 'faster-signatures'], wheel.extras())

        self.assertEqual(['keyring', 'keyrings.alt', 'pyxdg'], list(wheel.dependencies(extra='signatures')))
        self.assertEqual(['ed25519ll'], list(wheel.dependencies(extra='faster-signatures')))
        self.assertEqual(['pytest', 'pytest-cov'], list(wheel.dependencies(extra='test')))

    def test_split_environment(self):
        with self.assertRaises(markers.InvalidMarker):
            wheeltool.split_extra_from_environment_marker('')

        extra, environment = wheeltool.split_extra_from_environment_marker('extra == "foo"')
        self.assertEqual('foo', extra)
        self.assertEqual('', environment)

        # from ipython
        env = 'sys_platform != "win32"'
        extra, environment = wheeltool.split_extra_from_environment_marker(env)
        self.assertEqual('', extra)
        self.assertEqual(env, environment)

        # from mock
        env = '(python_version<"3.3" and python_version>="3") and extra == \'docs\''
        extra, environment = wheeltool.split_extra_from_environment_marker(env)
        self.assertEqual('docs', extra)
        self.assertEqual('(python_version < "3.3" and python_version >= "3")', environment)

        # from requests
        env = 'sys_platform == "win32" and (python_version == "2.7" or python_version == "2.6") and extra == \'socks\''
        extra, environment = wheeltool.split_extra_from_environment_marker(env)
        self.assertEqual('socks', extra)
        self.assertEqual('sys_platform == "win32" and (python_version == "2.7" or python_version == "2.6")', environment)

        # fake to ensure ands are remove correctly
        env = 'sys_platform == "win32" and extra == \'socks\' and python_version == "2.7"'
        extra, environment = wheeltool.split_extra_from_environment_marker(env)
        self.assertEqual('socks', extra)
        self.assertEqual('sys_platform == "win32" and python_version == "2.7"', environment)
        env = 'extra == \'socks\' and python_version == "2.7"'
        extra, environment = wheeltool.split_extra_from_environment_marker(env)
        self.assertEqual('socks', extra)
        self.assertEqual('python_version == "2.7"', environment)


_TENACITY_METADATA = '''Metadata-Version: 2.1
Name: tenacity
Version: 4.10.0
Summary: Retry code until it succeeeds
Home-page: https://github.com/jd/tenacity
Author: Julien Danjou
Author-email: julien@danjou.info
License: Apache 2.0
Platform: UNKNOWN
Classifier: Intended Audience :: Developers
Classifier: License :: OSI Approved :: Apache Software License
Classifier: Programming Language :: Python
Classifier: Programming Language :: Python :: 2.7
Classifier: Programming Language :: Python :: 3.5
Classifier: Programming Language :: Python :: 3.6
Classifier: Topic :: Utilities
Requires-Dist: six (>=1.9.0)
Requires-Dist: futures (>=3.0); (python_version=='2.7')
Requires-Dist: monotonic (>=0.6); (python_version=='2.7')

Tenacity
========
lots of text follows'''

_WHEEL_METADATA = u'''Metadata-Version: 2.1
Name: wheel
Version: 0.31.0
Summary: A built-package format for Python.
Home-page: https://github.com/pypa/wheel
Author: Daniel Holth
Author-email: dholth@fastmail.fm
Maintainer: Alex Gr\u00f6nholm
Maintainer-email: alex.gronholm@nextday.fi
License: MIT
Keywords: wheel,packaging
Platform: UNKNOWN
Classifier: Development Status :: 5 - Production/Stable
Classifier: Intended Audience :: Developers
Classifier: License :: OSI Approved :: MIT License
Classifier: Programming Language :: Python
Classifier: Programming Language :: Python :: 2
Classifier: Programming Language :: Python :: 2.7
Classifier: Programming Language :: Python :: 3
Classifier: Programming Language :: Python :: 3.4
Classifier: Programming Language :: Python :: 3.5
Classifier: Programming Language :: Python :: 3.6
Requires-Python: >=2.7, !=3.0.*, !=3.1.*, !=3.2.*, !=3.3.*
Provides-Extra: test
Provides-Extra: signatures
Provides-Extra: faster-signatures
Provides-Extra: faster-signatures
Requires-Dist: ed25519ll; extra == 'faster-signatures'
Provides-Extra: signatures
Requires-Dist: keyring; extra == 'signatures'
Requires-Dist: keyrings.alt; extra == 'signatures'
Provides-Extra: signatures
Requires-Dist: pyxdg; (sys_platform!="win32") and extra == 'signatures'
Provides-Extra: test
Requires-Dist: pytest (>=3.0.0); extra == 'test'
Requires-Dist: pytest-cov; extra == 'test'

Wheel
=====

A built-package format for Python.'''.encode('utf-8')