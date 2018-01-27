load(":rules_python_zip.bzl", "pyz_binary", "pyz_library", "pyz_test")

exports_files(["pytest_template.sh"])

config_setting(
    name = "linux",
    constraint_values = ["@bazel_tools//platforms:linux"],
    visibility=["//visibility:public"],
)

config_setting(
    name = "osx",
    constraint_values = ["@bazel_tools//platforms:osx"],
    visibility=["//visibility:public"],
)

pyz_library(
    name="pytest",
    wheels=[
        "@pyz_pytest_whl//file",
        "@pyz_six_whl//file",
        "@pyz_py_whl//file",
        "@pyz_funcsigs_whl//file",
        ":pluggy_whl"   ,
        "@pyz_attrs_whl//file",
        "@pyz_setuptools_whl//file",
    ],
    visibility=["//visibility:public"],
)

genrule(
    name="pluggy_whl",
    srcs=["@pyz_pluggy_tgz//file"],
    outs=["pluggy-0.6.0-py2.py3-none-any.whl"],
    # setuptools with PYTHONPATH=some_zip does not find the version in the zip: unzip it
    cmd="""$(location //pypi:pip) wheel \
        --quiet --disable-pip-version-check --no-cache-dir \
        --wheel-dir=$(@D) $(location @pyz_pluggy_tgz//file)""",
    tools=["//pypi:pip"],
)
