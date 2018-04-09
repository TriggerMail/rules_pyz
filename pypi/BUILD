load("//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_library", "pyz_test")

pyz_binary(
    name="pip",
    # wrapper to ensure setup.py is invoked with the right PYTHONPATH
    srcs=["pip_pyz.py"],
    deps=[":pip_lib"],
    # needed to find the bundled certs; see comment on pip_lib
    force_all_unzip=True,
    visibility=["//visibility:public"],
)

pyz_binary(
    name="wheeltool",
    srcs=["wheeltool.py"],
    deps=["//rules_python_zip:setuptools"],
    visibility=["//visibility:public"],
)
# checks imports: needs pkg_resources which is not in the standard library
sh_test(
    name="wheeltool_test",
    srcs=["wheeltool_test.sh"],
    data=[":wheeltool"],
    args=["$(location :wheeltool)"],
)

pyz_library(
    name="pip_lib",
    # pip bundles these certs and cannot read them from the zip
    # TODO: Only unzip these files? Or make an attribute apply to this lib
    # force_unzip=[
    #     "pip/_vendor/requests/cacerts.pem",
    #     "pip/_vendor/requests/certs.py",
    # ],
    deps=["//rules_python_zip:setuptools"],
    wheels=["@pypi_pip//file", "@pypi_wheel//file"],
)

py_binary(
    name="pip_generate_wrapper",
    srcs=["pip_generate_wrapper.py"],
    data=[
        ":pip",
        ":wheeltool",

        "//tools:pip_generate",
    ]
)
# checks tool path
sh_test(
    name="pip_generate_wrapper_test",
    srcs=["pip_generate_wrapper_test.sh"],
    data=[":pip_generate_wrapper"],
    args=["$(location :pip_generate_wrapper)"],
)

pyz_test(
    name="ssl_test",
    srcs=["ssl_test.py"],
    deps=[":pip_lib"],
    # needed to find the bundled certs; see comment on pip_lib
    force_all_unzip=True,
)

pyz_test(
    name="pip_setuptools_test",
    srcs=["pip_setuptools_test.py"],
    data=["setup.py", ":pip"]
)
