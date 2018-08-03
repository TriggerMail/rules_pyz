# Requires io_bazel_rules_docker to exist
load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
    container_repositories = "repositories"
)
load(
    "@io_bazel_rules_docker//python:image.bzl",
    py2_image_repositories = "repositories",
)
load(
    "@io_bazel_rules_docker//python3:image.bzl",
    py3_image_repositories = "repositories",
)
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")


# WORKSPACE repository macro to load dependencies to use pyz_image
def pyz_image_repositories():
    excludes = native.existing_rules().keys()

    container_repositories()
    py2_image_repositories()
    py3_image_repositories()

    if "dash_deb" not in excludes:
        http_file(
            name="dash_deb",
            urls=["http://http.us.debian.org/debian/pool/main/d/dash/dash_0.5.8-2.4_amd64.deb"],
            sha256="5084b7e30fde9c51c4312f4da45d4fdfb861ab91c1d514a164dcb8afd8612f65",
        )
    if "libc_bin_deb" not in excludes:
        http_file(
            name="libc_bin_deb",
            urls=["http://http.us.debian.org/debian/pool/main/g/glibc/libc-bin_2.24-11+deb9u3_amd64.deb"],
            sha256="05d14e9b122095142639dd0c5f9ac8a0dd7d6849eb1ff5b29721e181036e2b23",
        )
