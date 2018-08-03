load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# WORKSPACE repository macro to load dependencies to use pyz_image
def pyz_rules_docker_repositories():
    excludes = native.existing_rules().keys()

    # rules_docker
    if "io_bazel_rules_docker" not in excludes:
        http_archive(
            name = "io_bazel_rules_docker",
            url = "https://github.com/bazelbuild/rules_docker/archive/4338ecf45187a848d55a3651b6c1d70fe1ef6cce.tar.gz",
            sha256="1888bbd1d13637273f6968cfbef82c13c413d701647083a04e2e740cf80246a4",
            strip_prefix="rules_docker-4338ecf45187a848d55a3651b6c1d70fe1ef6cce"
        )
