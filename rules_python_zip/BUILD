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
        ":pluggy_whl"   ,
        "@pypi_attrs//file",
        "@pypi_funcsigs//file",
        "@pypi_more_itertools//file",
        "@pypi_py//file",
        "@pypi_pytest//file",
        "@pypi_six//file",
    ],
    deps=[":setuptools"],
    visibility=["//visibility:public"],
)

pyz_library(
    name="setuptools",
    wheels=["@pypi_setuptools//file"],
    visibility=["//visibility:public"],
)

genrule(
    name="pluggy_whl",
    srcs=["@pypi_pluggy_tgz//file"],
    outs=["pluggy-0.6.0-py2.py3-none-any.whl"],
    cmd="""$(location //pypi:pip) wheel \
        --quiet --disable-pip-version-check --no-cache-dir \
        --wheel-dir=$(@D) $(location @pypi_pluggy_tgz//file)""",
    tools=["//pypi:pip"],
)
