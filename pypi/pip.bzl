load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "wheel_build_content")


def pip_repositories():
    """WORKSPACE rules for generating PyPI dependencies."""

    build_content = wheel_build_content()

    existing = native.existing_rules()
    if 'pypi_pip' not in existing:
        http_archive(
            name = 'pypi_pip',
            url = 'https://files.pythonhosted.org/packages/0f/74/ecd13431bcc456ed390b44c8a6e917c1820365cbebcb6a8974d1cd045ab4/pip-10.0.1-py2.py3-none-any.whl',
            sha256 = '717cdffb2833be8409433a93746744b59505f42146e8d37de6c62b430e25d6d7',
            build_file_content=build_content,
            type="zip",
        )
    if 'pypi_wheel' not in existing:
        http_archive(
            name = 'pypi_wheel',
            url = 'https://files.pythonhosted.org/packages/81/30/e935244ca6165187ae8be876b6316ae201b71485538ffac1d718843025a9/wheel-0.31.1-py2.py3-none-any.whl',
            sha256 = '80044e51ec5bbf6c894ba0bc48d26a8c20a9ba629f4ca19ea26ecfcf87685f5f',
            build_file_content=build_content,
            type="zip",
        )
