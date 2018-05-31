#!/usr/bin/env bash
set -eu

# Allow passing additional flags: used to pass -B when running pytest
BAZEL_PYTHON_EXTRA_FLAGS=${BAZEL_PYTHON_EXTRA_FLAGS:-}

# if running from bazel, we need to look for the runfiles path
# if running as a subcommand inside a runfiles, this will not exist
RUNFILES="${TEST_SRCDIR:-${BASH_SOURCE[0]}.runfiles}"
MAIN_PATH="${RUNFILES}/{{MAIN_PATH}}"
if [ ! -e "$MAIN_PATH" ]; then
    MAIN_PATH="${BASH_SOURCE[0]}_exedir/__main__.py"
fi

# Set -E -S -s: Attempt to isolate the Python environment as much as possible
exec {{INTEPRETER_PATH}} ${BAZEL_PYTHON_EXTRA_FLAGS} -E -S -s "${MAIN_PATH}" $@
