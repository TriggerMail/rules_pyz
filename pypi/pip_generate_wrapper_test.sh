#!/bin/bash

set -euf -o pipefail

OUTPUT=$( $1 2>&1 || true)
echo $OUTPUT
# If it prints 'Usage of' then it at least ran
echo $OUTPUT | grep -q 'Usage of ' || (echo 'ERROR: OUTPUT DOES NOT MATCH'; exit 1)
