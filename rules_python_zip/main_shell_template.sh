#!/usr/bin/env bash
set -eu

# TODO: Use Python to avoid env/bash dependency?
# Python startup is ~10X slower, or ~3X even with -s -S -E

# Allow passing additional flags to python: used to pass -B so pytest does not write .pyc
BAZEL_PYTHON_EXTRA_FLAGS=${BAZEL_PYTHON_EXTRA_FLAGS:-}

# Find the runfiles so we can find the correct exedir
# if running inside bazel test, TEST_SRCDIR will be set to runfiles
# if running from another bazel binary, we need to find .runfiles on the path
# otherwise: running directly or from bazel run: use exe path + .runfiles
if [ -z ${TEST_SRCDIR+x} ]; then
    # TEST_SRCDIR is not set: check for .runfiles on the path
    if [[ "${BASH_SOURCE[0]}" = *".runfiles"* ]]; then
        RUNFILES=$(sed 's/\(^.*\.runfiles\).*/\1/' <<< "${BASH_SOURCE[0]}")
    else
        RUNFILES="${BASH_SOURCE[0]}.runfiles"
    fi
else
    RUNFILES=${TEST_SRCDIR}
fi

MAIN_PATH="${RUNFILES}/{{MAIN_PATH}}"
if [ ! -e "$MAIN_PATH" ]; then
    MAIN_PATH="${BASH_SOURCE[0]}_exedir/__main__.py"
fi

# Set -E -S -s: Attempt to isolate the Python environment as much as possible
exec {{INTEPRETER_PATH}} ${BAZEL_PYTHON_EXTRA_FLAGS} -E -S -s "${MAIN_PATH}" "$@"
