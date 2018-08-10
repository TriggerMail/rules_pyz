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
~/bin/bazel test --keep_going --test_output=errors //...
~/bin/bazel build //...

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

# Ensure the rules work with older versions of Bazel
# Copy the test workspace elsewhere and go to it
# Installing Bazel inside a workspace executes tools/bazel.rc which can break old versions
cp -r testworkspace /tmp
COMMIT=$(git rev-parse HEAD)
REMOTE=file://$(pwd)
perl -pi -e "s/REPLACECOMMIT/${COMMIT}/" /tmp/testworkspace/WORKSPACE
perl -pi -e "s#REPLACEREMOTE#${REMOTE}#" /tmp/testworkspace/WORKSPACE
cd /tmp/testworkspace

OLD_BAZEL_VERSION=0.14.1
OLD_BAZEL_INSTALLER="bazel-${OLD_BAZEL_VERSION}-installer-linux-x86_64.sh"
OLD_BAZEL_PREFIX=${HOME}/bazel-${OLD_BAZEL_VERSION}
wget https://github.com/bazelbuild/bazel/releases/download/${OLD_BAZEL_VERSION}/${OLD_BAZEL_INSTALLER}
chmod a+x ${OLD_BAZEL_INSTALLER}
./${OLD_BAZEL_INSTALLER} --prefix=${OLD_BAZEL_PREFIX}

${OLD_BAZEL_PREFIX}/bin/bazel test //...
${OLD_BAZEL_PREFIX}/bin/bazel run //:binary
${OLD_BAZEL_PREFIX}/bin/bazel version
