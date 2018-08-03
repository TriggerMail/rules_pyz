workspace(name = "com_bluecore_rules_pyz")

# Always load from the fully-qualified path inside this repository:
# Otherwise Bazel does not consider separate copies to be the same. See:
# https://github.com/bazelbuild/bazel/issues/3493
load("@com_bluecore_rules_pyz//rules_python_zip:rules_python_zip.bzl", "pyz_repositories")
pyz_repositories()

load("@com_bluecore_rules_pyz//pypi:pip.bzl", "pip_repositories")
pip_repositories()

load("@com_bluecore_rules_pyz//third_party/pypi:pypi_rules.bzl", "pypi_repositories")
pypi_repositories()

load("@com_bluecore_rules_pyz//pyz_image:docker.bzl", "pyz_rules_docker_repositories")
pyz_rules_docker_repositories()
load("@com_bluecore_rules_pyz//pyz_image:image.bzl", "pyz_image_repositories")
pyz_image_repositories()
