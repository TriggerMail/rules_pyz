#!/bin/bash

set -euf -o pipefail

OUTPUT=$( $1 2>&1 || true)
echo $OUTPUT
echo $OUTPUT | grep -q 'Usage: wheeltool.py' || (echo 'ERROR: OUTPUT DOES NOT MATCH'; exit 1)
