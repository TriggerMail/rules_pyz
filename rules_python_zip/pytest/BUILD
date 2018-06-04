load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_library")

# Must be defined a separate BUILD file from rules_python_zip.bzl:
# If the definitions for @pypi_* don't exist yet, it fails when parsing
# the BUILD file
pyz_library(
    name="pytest",
    deps=[
        "@pypi_atomicwrites//:lib",
        "@pypi_attrs//:lib",
        "@pypi_funcsigs//:lib",
        "@pypi_more_itertools//:lib",
        "@pypi_pluggy//:lib",
        "@pypi_py//:lib",
        "@pypi_pytest//:lib",
        "@pypi_setuptools//:lib",
        "@pypi_six//:lib",
    ],
    visibility=["//visibility:public"],
)
