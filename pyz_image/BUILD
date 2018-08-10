load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_binary", "pyz_test")
load("@com_bluecore_rules_pyz//pyz_image:pyz_image.bzl", "pyz2_image", "pyz3_image", "rename_debs")
load("@io_bazel_rules_docker//container:container.bzl", "container_image", "container_layer")

exports_files(["zip_to_tar.py", "ld.so.cache"])

# Workaround for https://github.com/bazelbuild/bazel/issues/5633
renamed_debs = rename_debs(["@dash_deb//file", "@libc_bin_deb//file"])

# Fixes distroless bugs:
# https://github.com/GoogleContainerTools/distroless/issues/150
container_image(
    name="py2_image_base",
    base="@py_image_base//image",
    debs=renamed_debs,
    layers=[":ld_so_cache_layer"],
    visibility=["//visibility:public"],
)
# TODO: explicitly create a tar to avoid an extra layer?
container_layer(
    name="ld_so_cache_layer",
    files=[":ld.so.cache"],
    mode="0644",
    directory="/etc",
)
container_image(
    name="py3_image_base",
    base="@py3_image_base//image",
    debs=renamed_debs,
    layers=[":ld_so_cache_layer"],
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
    tags=["ci_disabled"],
)

genrule(
    name="ld_so_cache",
    outs=["ld.so.cache.new"],
    cmd="$(location :generate_ldconfig_cache) $@",
    tools = [":generate_ldconfig_cache"],
    tags=["ci_disabled"],
)

sh_test(
    name="check_ld_so_cache",
    srcs=["check_ld_so_cache.py"],
    data=[":ld.so.cache.new", ":ld.so.cache"],
    tags=["ci_disabled"],
)
