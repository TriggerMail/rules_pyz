#!/bin/bash

# Get the path to runfiles relative to this script so it will work
# even when executed from outside this path
# TODO: Replace __main__ with the correct workspace
RUNFILES=${BASH_SOURCE[0]}.runfiles/__main__
PYTHONPATH=${RUNFILES} exec "${RUNFILES}/{main_script_path}"
