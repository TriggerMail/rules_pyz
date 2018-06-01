#!/bin/bash

set -euf -o pipefail


RUNFILES=${TEST_SRCDIR:-${BASH_SOURCE[0]}.runfiles}

# pytest rewrites bytecode into __pycache__: no point with Bazel's sandbox
export BAZEL_PYTHON_EXTRA_FLAGS="-B"

# no:cacheprovider: disable creating .cache dir:
# https://docs.pytest.org/en/latest/cache.html#cache-provider
exec "${RUNFILES}/{{PYTEST_RUNNER}}" -p no:cacheprovider \
  ${XML_OUTPUT_FILE:+"--junit-xml=$XML_OUTPUT_FILE"} "$@" {{SRCS_LIST}}
