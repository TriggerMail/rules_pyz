#!/bin/bash
# Tests that running things from outside Bazel work as expected

set -euf -o pipefail
set -x

bazel build //tests:trivial_test
bazel-bin/tests/trivial_test

echo "SUCCESS"
