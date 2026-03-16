#!/bin/bash

# interrupt on error
set -e
#set -eu # TODO: use this to catch undefined variables
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

if [[ $# -ne 0 ]] && [[ $# -ne 1 ]]; then
    echo "Prepare sanager tests"
    echo "Usage:"
    echo "$0 \"\""
    echo "or with ZFS (prefered when ZFS available)"
    echo "$0 zpool/dataset/path"
    echo "Example:"
    echo "$0 myPool/vms/sanager"

    exit 1;
fi

# load configuration
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../misc/disks.sh"

function main {
    local VM_ZPOOL_DATASET_PARENT="$1"

    if [[ -z "$VM_ZPOOL_DATASET_PARENT" ]]; then
        echo "ZFS **NOT** used"
        return
    fi

    echo "ZFS usage enabled"

    mkdir -p "$TEST_DIR"

    cat <<EOF > "$TEST_DIR/customConfig.sh"
SANAGER_TESTS_INITIALIZED="true"
VM_ZPOOL_DATASET_PARENT="$VM_ZPOOL_DATASET_PARENT"

if [[ -n "$VM_ZPOOL_DATASET_PARENT" ]] && ! command -v zpool >/dev/null 2>&1; then
    echo "ZFS use requested, but ZFS doesn't seem to be installed"
    exit 1
fi

if [[ -n "$VM_ZPOOL_DATASET_PARENT" ]] && ! isPathZpoolDatasetPath "$VM_ZPOOL_DATASET_PARENT"; then
    echo "zpool dataset path \"$VM_ZPOOL_DATASET_PARENT\" doesn't exist"
    exit 1
fi

USER_ME=\`whoami\`

if ! zfs allow "$VM_ZPOOL_DATASET_PARENT" | grep -q "\$USER_ME"; then
    echo "Missing permissions for creating sub-datasets for '$VM_ZPOOL_DATASET_PARENT'"
    echo "To add permissions use:"
    echo "sudo zfs allow \$USER_ME create,mount,mountpoint,destroy,volsize,volblocksize,compression,sync,primarycache,logbias,refreservation,snapshot,send,receive $VM_ZPOOL_DATASET_PARENT"

    exit 1
fi
EOF

    echo "Sanager tests initialized"
}

main "$1"
