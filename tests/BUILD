load("//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_test", "pyz_library")

# Trivial python binary and test
pyz_binary(
    name="helloworld",
    srcs=["helloworld.py"],
)
sh_test(
    name="helloworld_test",
    srcs=["command_output_tester.py"],
    data=[":helloworld"],
    args=["--command=$(location :helloworld)", "--expected-output='hello world'"],
)

# Multiple files and imports
pyz_binary(
    name="hello_import",
    srcs=["hello_import.py", "helloworld.py"],
)
sh_test(
    name="hello_import_test",
    srcs=["command_output_tester.py"],
    data=[":hello_import"],
    args=["--command=$(location :hello_import)", "--expected-output='hello_import done'"],
)
py_binary(
    name="hello_import_builtin",
    main="hello_import.py",
    srcs=["hello_import.py", "helloworld.py"],
)
sh_test(
    name="hello_import_builtin_test",
    srcs=["command_output_tester.py"],
    data=[":hello_import_builtin"],
    args=["--command=$(location :hello_import_builtin)", "--expected-output='hello_import done'",
        "--no-unzip"],
)

# Pythonroot test
pyz_library(
    name="short_import",
    srcs=["shortimport.py"],
    wheels=["@pypi_asn1crypto//file"],
    pythonroot=".",
)
pyz_binary(
    name="use_shortimport",
    srcs=["use_shortimport.py", "helloworld.py"],
    deps=[":short_import"],
)
sh_test(
    name="use_shortimport_test",
    srcs=["command_output_tester.py"],
    data=[":use_shortimport"],
    args=["--command=$(location :use_shortimport)", "--expected-output=shortimport"],
)

# Tests zip entry point import side effects
pyz_binary(
    name="no_sys_import",
    srcs=["no_sys_import.py"],
)
sh_test(
    name="no_sys_import_test",
    srcs=["command_output_tester.py"],
    data=[":no_sys_import"],
    args=["--command=$(location :no_sys_import)", "--expected-output=NameError", "--expect-failure"],
)

# Tests the base pytest rule works
pyz_binary(
    name="pytest_bin",
    entry_point="pytest",
    deps=["//rules_python_zip:pytest"]
)
sh_test(
    name="pytest_test",
    srcs=["command_output_tester.py"],
    data=[":pytest_bin"],
    args=["--command=$(location :pytest_bin)", "--expected-output='no tests ran'", "--expect-failure"],
)

# An actual test! With verification that it produces XML output
pyz_test(
    name="trivial_test",
    srcs=["trivial_test.py"],
)
sh_test(
    name="pytest_output_test",
    srcs=["pytest_output_test.py"],
    data=[":trivial_test"],
    args=["$(location :trivial_test)"],
)

pyz_library(
    name="module",
    srcs=["module.py"],
)
pyz_test(
    name="import_lib_test",
    srcs=["import_lib_test.py"],
    deps=[":module"],
)

pyz_test(
    name="import_wheel_test",
    srcs=["import_wheel_test.py"],
    wheels=["@pyz_py_whl//file"],
)

pyz_binary(
    name="native_wheel",
    srcs=["native_wheel.py"],
    deps=[
        "//third_party/pypi:bcrypt",
        "//third_party/pypi:cffi",
    ],
)
sh_test(
    name="native_wheel_test",
    srcs=["command_output_tester.py"],
    data=[":native_wheel"],
    args=["--command=$(location :native_wheel)", "--expected-output='hello from printf'"],
)

pyz_binary(
    name="native_wheel_nested",
    srcs=["native_wheel_nested.py"],
    deps=["//third_party/pypi:cryptography"]
)
sh_test(
    name="native_wheel_nested_test",
    srcs=["command_output_tester.py"],
    data=[":native_wheel_nested"],
    args=["--command=$(location :native_wheel_nested)",
        "--expected-output='openssl.backend.Backend object'"],
)

pyz_binary(
    name="wheel_google_cloud",
    srcs=["wheel_google_cloud.py"],
    deps=["//third_party/pypi:google_cloud_datastore"]
)
sh_test(
    name="wheel_google_cloud_test",
    srcs=["command_output_tester.py"],
    data=[":wheel_google_cloud"],
    args=["--command=$(location :wheel_google_cloud)",
        "--expected-output='google.cloud.datastore'"],
)

pyz_binary(
    name="force_unzip",
    srcs=["force_unzip.py"],
    data=["resource.txt"],
    zip_safe=False,
)
sh_test(
    name="force_unzip_test",
    srcs=["command_output_tester.py"],
    data=[":force_unzip"],
    args=["--command=$(location :force_unzip)",
        "--expected-output='hello resource.txt'"],
)

# tests zip entry point site-packages and tests pyz_test data attribute
pyz_binary(
    name="virtualenv",
    deps=["//third_party/pypi:virtualenv"],
    entry_point="virtualenv",
    force_all_unzip=True,
)
pyz_binary(
    name="import_site_packages",
    srcs=["import_site_packages.py"],
)
sh_test(
    name="import_site_packages_test",
    srcs=["command_output_tester.py"],
    data=[":import_site_packages"],
    args=["--command=$(location :import_site_packages)", "--expected-output='SUCCESS'"],
)
pyz_test(
    name="virtualenv_imports_test",
    srcs=["virtualenv_imports_test.py"],
    data=[":virtualenv", ":import_site_packages"]
)

pyz_binary(
    name="print_file_path",
    srcs=["print_file_path.py"],
)
pyz_binary(
    name="print_file_path_force_all_unzip",
    srcs=["print_file_path.py"],
    force_all_unzip=True,
)
pyz_test(
    name="print_file_path_test",
    srcs=["print_file_path_test.py"],
    data=[":print_file_path", ":print_file_path_force_all_unzip"],
)

pyz_binary(
    name="interpreter",
    interpreter=True,
    deps=["//third_party/pypi:google_cloud_datastore"],
)
pyz_test(
    name="interpreter_test",
    srcs=["interpreter_test.py"],
    data=[":interpreter"],
)

pyz_test(
    name="scipy_test",
    srcs=["scipy_test.py"],
    deps=["//third_party/pypi:scipy"],
)
