def pip_repositories():
    """WORKSPACE rules for generating PyPI dependencies."""

    existing = native.existing_rules().keys()
    if 'pypi_pip_whl' not in existing:
        native.http_file(
            name = 'pypi_pip_whl',
            url = 'https://pypi.python.org/packages/b6/ac/7015eb97dc749283ffdec1c3a88ddb8ae03b8fad0f0e611408f196358da3/pip-9.0.1-py2.py3-none-any.whl',
            sha256 = '690b762c0a8460c303c089d5d0be034fb15a5ea2b75bdf565f40421f542fefb0'
        )
    if 'pypi_wheel_whl' not in existing:
        native.http_file(
            name = 'pypi_wheel_whl',
            url = 'https://pypi.python.org/packages/0c/80/16a85b47702a1f47a63c104c91abdd0a6704ee8ae3b4ce4afc49bc39f9d9/wheel-0.30.0-py2.py3-none-any.whl',
            sha256 = 'e721e53864f084f956f40f96124a74da0631ac13fbbd1ba99e8e2b5e9cafdf64'
        )
