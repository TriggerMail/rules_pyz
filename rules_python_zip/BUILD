load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_library", "pyz_test")

exports_files(["pytest_template.sh", "main_template.py", "main_shell_template.sh", "__init__.py", "linkzip.py"])

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
