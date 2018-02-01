load("//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_test", "pyz_library")

# tests that pyz_* rules can be in //third_party (need "licenses")
pyz_binary(
    name="licenses",
    licenses=["notice"],
    interpreter=True,
)
pyz_library(
    name="licenses_lib",
    licenses=["notice"],
)
pyz_test(
    name="licenses_test",
    srcs=["licenses_test.py"],
    licenses=["notice"],
)
