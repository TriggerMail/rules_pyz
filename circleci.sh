#!/bin/bash
set -euf -o pipefail

# Download and install Bazel
BAZEL_VERSION=0.14.0
BAZEL_INSTALLER="bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${BAZEL_INSTALLER}
chmod a+x ${BAZEL_INSTALLER}
./${BAZEL_INSTALLER} --user

# Ensure everything can be built and tested
~/bin/bazel test --test_output=errors //...
~/bin/bazel build //...

# Ensure the Go tools can be built
./update_tools.py

# Ensure Go source is formatted
NOT_FORMATTED=$(go fmt ./...)
if [[ -n "$NOT_FORMATTED" ]]; then
    echo "ERROR: Files not formatted with go fmt:" > /dev/stderr
    echo "$NOT_FORMATTED" > /dev/stderr
    exit 1
fi
