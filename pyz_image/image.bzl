# Requires io_bazel_rules_docker to exist
load(
    "@io_bazel_rules_docker//container:container.bzl",
    "container_pull",
    container_repositories = "repositories"
)


# WORKSPACE repository macro to load dependencies to use pyz_image
def pyz_image_repositories():
    excludes = native.existing_rules().keys()

    container_repositories()

    # Use a more recent distroless image than rules_docker
    # Includes fixes for os.system and ctypes.find_library:
    # https://github.com/GoogleContainerTools/distroless/issues/150
    if "pyz2_image_base" not in excludes:
        container_pull(
            name = "pyz2_image_base",
            registry = "gcr.io",
            repository = "distroless/python2.7",
            digest = "sha256:05d6f4e90bb4924daa00639a4b47cf172718347f41b999cd8a8ab2665a8fdf09",
        )
    if "pyz3_image_base" not in excludes:
        container_pull(
            name = "pyz3_image_base",
            registry = "gcr.io",
            repository = "distroless/python3",
            digest = "sha256:8fc8c9055459ede89337c843556e3aaa22dd88b6ef9b2df8f0a67cfdf4fc40bd",
        )
