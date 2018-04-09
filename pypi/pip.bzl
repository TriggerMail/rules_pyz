def pip_repositories():
    """WORKSPACE rules for generating PyPI dependencies."""

    existing = native.existing_rules().keys()
    if 'pypi_pip' not in existing:
        native.http_file(
            name = 'pypi_pip',
            url = 'https://pypi.python.org/packages/ac/95/a05b56bb975efa78d3557efa36acaf9cf5d2fd0ee0062060493687432e03/pip-9.0.3-py2.py3-none-any.whl',
            sha256 = 'c3ede34530e0e0b2381e7363aded78e0c33291654937e7373032fda04e8803e5'
        )
    if 'pypi_wheel' not in existing:
        native.http_file(
            name = 'pypi_wheel',
            url = 'https://pypi.python.org/packages/1b/d2/22cde5ea9af055f81814f9f2545f5ed8a053eb749c08d186b369959189a8/wheel-0.31.0-py2.py3-none-any.whl',
            sha256 = '9cdc8ab2cc9c3c2e2727a4b67c22881dbb0e1c503d592992594c5e131c867107'
        )
