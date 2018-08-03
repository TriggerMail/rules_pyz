#!/bin/bash
set -euf -o pipefail

set -x

# Download and install Bazel
BAZEL_VERSION=0.16.0
BAZEL_INSTALLER="bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh"
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/${BAZEL_INSTALLER}
chmod a+x ${BAZEL_INSTALLER}
./${BAZEL_INSTALLER} --user

# Ensure everything can be built and tested
BAZEL_CI_TAG_FILTER=-ci_disabled
~/bin/bazel test --build_tag_filters=${BAZEL_CI_TAG_FILTER} --test_tag_filters=${BAZEL_CI_TAG_FILTER} --keep_going --test_output=errors //...
~/bin/bazel build --build_tag_filters=${BAZEL_CI_TAG_FILTER} //...

# Ensure the Go tools can be built and the script works with both versions of python
python2.7 ./update_tools.py
python3 ./update_tools.py

# Ensure Go source is formatted
NOT_FORMATTED=$(go fmt ./...)
if [[ -n "$NOT_FORMATTED" ]]; then
    echo "ERROR: Files not formatted with go fmt:" > /dev/stderr
    echo "$NOT_FORMATTED" > /dev/stderr
    exit 1
fi
