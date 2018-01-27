#!/bin/bash

set -euf -o pipefile

OS=`uname`

PREFIX="tools/simplepack"
SUFFIXES="-x64-linux -x64-osx"
for SUFFIX in ${SUFFIXES}; do
  PATH="${PREFIX}${SUFFIX}"
  echo "WTF" $PATH
  pwd
  ls
  ls tools
  if [ -x "${PATH}" ]; then
    exec ${PATH} $@
  fi
done

echo "Error: Failed to find simplepack for OS: ${OS}" > /dev/stderr
exit 1
