#!/bin/bash
set -euf -o pipefail

# Download and install Bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.13.0/bazel-0.13.0-installer-linux-x86_64.sh
chmod a+x bazel-0.13.0-installer-linux-x86_64.sh
./bazel-0.13.0-installer-linux-x86_64.sh --user

# Ensure everything can be built and tested
~/bin/bazel build //...
~/bin/bazel test //...

# Ensure the Go tools can be built
./update_tools.py

# Ensure Go source is formatted
NOT_FORMATTED=$(go fmt ./...)
if [[ -n "$NOT_FORMATTED" ]]; then
    echo "ERROR: Files not formatted with go fmt:" > /dev/stderr
    echo "$NOT_FORMATTED" > /dev/stderr
    exit 1
fi
