load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_test")

exports_files(["zip_to_tar.py"])

pyz_test(
    name="zip_to_tar_test",
    srcs=["zip_to_tar_test.py", "zip_to_tar.py"],
    pythonroot=".",
)
