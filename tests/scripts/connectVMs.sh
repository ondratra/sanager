#!/bin/bash

# interrupt on error
set -e
#set -eu # TODO: use this to catch undefined variables
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

if [[ $# -lt 3 ]]; then
    echo "Connect multiple VMs via a new network"
    echo "Usage:",
    echo "$0 NETWORK_INDEX VM_NAME_1 VM_NAME_2 [...VM_NAME_X]"
    echo "Example:"
    echo "$0 1 Sanager_MySpecificUseVM Sanager_MyAnotherUseVM"
    echo "NETWORK_INDEX must be unique"

    exit 1;
fi

# load configuration
source "$SCRIPT_DIR/../config.sh"

source "$SCRIPT_DIR/../misc/utils.sh"
source "$SANAGER_MAIN_DIR/src/lowLevel/utilities.sh"

connectVMs $@