load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_test", "pyz_library")

load(":pyz_output_test.bzl", "pyz_output_test")

# Trivial python binary and test
pyz_binary(
    name="helloworld",
    srcs=["helloworld.py"],
)
pyz_output_test(
    name="helloworld_test",
    pyz_binary=":helloworld",
    expected_output="hello world",
)

# Trivial python binary and test
pyz_binary(
    name="hello_py3",
    srcs=["hello_py3.py"],
    interpreter_path="python3",
)
pyz_output_test(
    name="hello_py3_test",
    pyz_binary=":hello_py3",
    expected_output="bytes == unicode? False",
    tags=["python3"],
)

# Had a bug where entry_point got called twice
pyz_binary(
    name="helloworld_entry_point",
    entry_point="helloworld",
    deps=[":helloworld_lib"],
)
pyz_library(
    name="helloworld_lib",
    srcs=["helloworld.py"],
    pythonroot=".",
)
pyz_output_test(
    name="helloworld_entry_point_test",
    pyz_binary=":helloworld_entry_point",
    expected_output="hello world",
)

# Multiple files and imports
pyz_binary(
    name="hello_import",
    srcs=["hello_import.py", "helloworld.py"],
)
pyz_output_test(
    name="hello_import_test",
    pyz_binary=":hello_import",
    expected_output="hello_import done",
)

# Pythonroot test
pyz_library(
    name="short_import",
    srcs=["shortimport.py"],
    deps=["//third_party/pypi:asn1crypto"],
    pythonroot=".",
)
pyz_binary(
    name="use_shortimport",
    srcs=["use_shortimport.py", "helloworld.py"],
    deps=[":short_import"],
)
pyz_output_test(
    name="use_shortimport_test",
    pyz_binary=":use_shortimport",
    expected_output="shortimport\n",
)

# Tests zip entry point import side effects
pyz_binary(
    name="no_sys_import",
    srcs=["no_sys_import.py"],
)
pyz_output_test(
    name="no_sys_import_test",
    pyz_binary=":no_sys_import",
    expected_output="NameError",
    expect_failure=True,
)

# Tests the base pytest rule works
pyz_binary(
    name="pytest_bin",
    entry_point="pytest",
    deps=["//rules_python_zip/pytest"]
)
pyz_output_test(
    name="pytest_test",
    pyz_binary=":pytest_bin",
    expected_output="pytest-warnings:",
    extra_arg="--help",
)

# An actual test! With verification that it produces XML output
pyz_test(
    name="trivial_test",
    srcs=["trivial_test.py"],
    size="small",
    timeout="short",
    flaky=False,
    local=0,
    tags=["unused-but-ensures-tags-work"],
)
sh_test(
    name="pytest_output_test",
    srcs=["pytest_output_test.py"],
    data=[":trivial_test"],
    args=["$(location :trivial_test)"],
)

pyz_test(
    name="trivial_test_pythonroot",
    srcs=["trivial_test.py"],
    pythonroot=".",
    size="small",
    timeout="short",
    flaky=False,
    local=0,
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

pyz_binary(
    name="native_wheel",
    srcs=["native_wheel.py"],
    deps=[
        "//third_party/pypi:bcrypt",
        "//third_party/pypi:cffi",
    ],
)
pyz_output_test(
    name="native_wheel_test",
    pyz_binary=":native_wheel",
    expected_output="hello from printf",
)

pyz_binary(
    name="native_wheel_nested",
    srcs=["native_wheel_nested.py"],
    deps=["//third_party/pypi:cryptography"]
)
pyz_output_test(
    name="native_wheel_nested_test",
    pyz_binary=":native_wheel_nested",
    expected_output="openssl.backend.Backend object",
)

pyz_binary(
    name="wheel_google_cloud",
    srcs=["wheel_google_cloud.py"],
    deps=["//third_party/pypi:google_cloud_datastore"]
)
pyz_output_test(
    name="wheel_google_cloud_test",
    pyz_binary=":wheel_google_cloud",
    expected_output="google.cloud.datastore",
)

# TODO: We always unzip in these rules for now: Add test when we enable zip_safe=True
pyz_binary(
    name="force_unzip",
    srcs=["force_unzip.py"],
    data=["resource.txt"],
)
pyz_output_test(
    name="force_unzip_test",
    pyz_binary=":force_unzip",
    expected_output="hello resource.txt",
)

# tests zip entry point site-packages and tests pyz_test data attribute
pyz_binary(
    name="virtualenv",
    deps=["//third_party/pypi:virtualenv"],
    entry_point="virtualenv",
)
pyz_binary(
    name="import_site_packages",
    srcs=["import_site_packages.py"],
)
pyz_output_test(
    name="import_site_packages_test",
    pyz_binary=":import_site_packages",
    expected_output="SUCCESS",
)
pyz_test(
    name="virtualenv_imports_test",
    srcs=["virtualenv_imports_test.py"],
    data=[":virtualenv", ":import_site_packages", ":import_site_packages_exezip", ]
)

pyz_binary(
    name="print_file_path",
    srcs=["print_file_path.py"],
)
pyz_test(
    name="print_file_path_test",
    srcs=["print_file_path_test.py"],
    data=[
        ":print_file_path",
        ":print_file_path_exezip"
    ],
)

pyz_binary(
    name="interpreter",
    interpreter=True,
    deps=["//third_party/pypi:google_cloud_datastore"],
)
pyz_test(
    name="interpreter_test",
    srcs=["interpreter_test.py"],
    data=[":interpreter", ":interpreter_exezip"],
)

# Tests a complicated native code dependency
pyz_test(
    name="scipy_test",
    srcs=["scipy_test.py"],
    deps=["//third_party/pypi:scipy"],
)

# Tests the interpreter_path attribute
pyz_binary(
    name="interpreter_path",
    srcs=["interpreter_path.py"],
    interpreter_path="/usr/bin/python2.7",
)
pyz_test(
    name="interpreter_path_test",
    srcs=["interpreter_path_test.py"],
    interpreter_path="/usr/bin/python2.7",
    data=[":interpreter_path"],
)

pyz_test(
    name="init_rewrite_test",
    srcs=["init_rewrite_test.py"],
    deps=[":coding"],
)
pyz_library(
    name="coding",
    srcs=["coding/__init__.py"],
    # force this to be unpacked, which triggers rewriting the __init__ file
    # previously caused a SyntaxError because it moved the coding directive
    zip_safe=False,
)

pyz_output_test(
    name="fork_test",
    pyz_binary=":fork_test_bin",
    expected_output="SUCCESS",
)
pyz_binary(
    name="fork_test_bin",
    srcs=["fork_test.py"],
    deps=[":coding"]
)

pyz_binary(
    name="pkg_resources_weirdness",
    srcs=["pkg_resources_weirdness.py"],
    deps=[
        "//third_party/pypi:google_cloud_datastore",
    ],
)
pyz_test(
    name="pkg_resources_weirdness_test",
    srcs=["pkg_resources_weirdness_test.py"],
    data=[":pkg_resources_weirdness"],
)

pyz_test(
    name="grpc_ssl_test",
    srcs=["grpc_ssl_test.py"],
    deps=["//third_party/pypi:google_cloud_datastore"],
)

pyz_test(
    name="certifi_path_test",
    srcs=["certifi_path_test.py"],
    deps=["//third_party/pypi:certifi"],
)

pyz_binary(
    name="pytz_example",
    srcs=["pytz_example.py"],
    deps=["//third_party/pypi:pytz"],
)
pyz_output_test(
    name="pytz_example_test",
    pyz_binary=":pytz_example",
    expected_output="SUCCESS",
)

pyz_binary(
    name="executable_data",
    srcs=["executable_data.py"],
    data=["executable.sh"],
    zip_safe=False,
)
pyz_output_test(
    name="executable_data_test",
    pyz_binary=":executable_data",
    expected_output="hello from executable.sh",
)

pyz_binary(
    name="run_other",
    srcs=["run_other.py"],
    data=[":helloworld"],
)
pyz_output_test(
    name="run_other_test",
    pyz_binary=":run_other",
    expected_output="run_other output: hello world",
)

pyz_binary(
    name="python_envvars",
    srcs=["python_envvars.py"],
)
pyz_output_test(
    name="python_envvars_test",
    pyz_binary="python_envvars",
    expected_output="PYTHON_EXAMPLE=should be found",
    extra_arg="$(location :python_envvars_exezip)",
)

pyz_test(
    name="linkzip_test",
    srcs=["linkzip_test.py"],
    data=["//rules_python_zip:linkzip.py"],
)
