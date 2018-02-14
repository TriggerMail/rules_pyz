#!/bin/bash

set -euf -o pipefail


RUNFILES="${TEST_SRCDIR:-${BASH_SOURCE[0]}.runfiles}"
# export TEST_TMPDIR="${TEST_TMPDIR:-$(mktemp -d)}"

# pytest rewrites bytecode into __pycache__: no point with Bazel's sandbox
export PYTHONDONTWRITEBYTECODE=1

# TODO: Figure out the correct workspace argument
# no:cacheprovider: disable creating .cache dir:
# https://docs.pytest.org/en/latest/cache.html#cache-provider
exec "${RUNFILES}/__main__/{{PYTEST_RUNNER}}" -p no:cacheprovider \
  ${XML_OUTPUT_FILE:+"--junit-xml=$XML_OUTPUT_FILE"} "$@" {{SRCS_LIST}}
