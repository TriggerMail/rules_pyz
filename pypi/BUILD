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

pyz_library(
    name="pip_lib",
    # pip bundles these certs and cannot read them from the zip
    # TODO: Only unzip these files? Or make an attribute apply to this lib
    # force_unzip=[
    #     "pip/_vendor/requests/cacerts.pem",
    #     "pip/_vendor/requests/certs.py",
    # ],
    wheels=["@pyz_pip_whl//file", "@pyz_wheel_whl//file", "@pyz_setuptools_whl//file"],
)

py_binary(
    name="pip_generate_wrapper",
    srcs=["pip_generate_wrapper.py"],
    data=[
        ":pip",
        ":wheeltool.py",

        "//tools:pip_generate",
    ]
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
