load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_test")
load("@com_bluecore_rules_pyz//pyz_image:pyz_image.bzl", "pyz2_image", "pyz3_image")
load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_layer")

exports_files(["zip_to_tar.py", "ld.so.cache"])

alias(
    name="py2_image_base",
    actual="@pyz2_image_base//image",
    visibility=["//visibility:public"],
)
alias(
    name="py3_image_base",
    actual="@pyz3_image_base//image",
    visibility=["//visibility:public"],
)

pyz_test(
    name="zip_to_tar_test",
    srcs=["zip_to_tar_test.py", "zip_to_tar.py"],
    pythonroot=".",
)

# Verifies that image_check.py runs outside of the docker container
sh_test(
    name="image_check_test",
    srcs=["image_check.py"],
)
sh_test(
    name="image_check_test_py3",
    srcs=["image_check_test_py3.sh"],
    data=[":image_check.py"],
)

pyz_binary(
    name="image_check_binary",
    srcs=["image_check.py"],
)

pyz2_image(
    name="image_check_py2_image",
    binary=":image_check_binary",
)

pyz3_image(
    name="image_check_py3_image",
    binary=":image_check_binary",
)

# Run image_check inside a pyz*_image to verify the Python standard library works
sh_test(
    name="image_check_image_test",
    srcs=["image_check_image_test.py"],
    data=[":image_check_py2_image", ":image_check_py3_image"],
)

sh_binary(
    name="generate_ldconfig_cache",
    srcs=["generate_ldconfig_cache.py"],
    data=[":py2_image_base"],
)

genrule(
    name="ld_so_cache",
    outs=["ld.so.cache.new"],
    cmd="$(location :generate_ldconfig_cache) $@",
    tools = [":generate_ldconfig_cache"],
)

sh_test(
    name="check_ld_so_cache",
    srcs=["check_ld_so_cache.py"],
    data=[":ld.so.cache.new", ":ld.so.cache"],
)
