#!/bin/bash

# interrupt on error
set -e
#set -eu # TODO: use this to catch undefined variables
#set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

ZFS_DATASET=""
ZFS_DATASET_OS=""
ZFS_FORKS_DATASET=""
ZFS_FORKS_DATASET_OS=""

function displayHelp {
    echo "Prepare sanager tests"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "--zfsDataset <value> default zfs dataset - mandatory if any other zfs-related parameter is used"
    echo "--zfsDatasetOs <value> dataset used for VM OS disks"
    echo "--zfsForksDataset <value> default zfs dataset for all forks"
    echo "--zfsForksDatasetOs <value> default zfs dataset for all forks "
    echo "-h, --help show this help"
    echo ""
    echo "Examples:"
    echo "$0 # uses qcow2 files for storage"
    echo "$0 --zfsDataset zpool/sanager/tests/generic"
    echo "$0 --zfsDataset zpool/sanager/tests/generic --zfsDatasetOs zpoolsanager/tests/os"
    echo "$0 --zfsDataset zpool/sanager/tests/generic --zfsDatasetOs zpoolsanager/tests/os --zfsForksDataset zpool/sanager/forks/generic --zfsForksDatasetOs zpoolsanager/forks/os"

    exit 0
}

function parseArgs {
    function invalidArguments {
        echo "Error: Invalid arguments."
        echo ""
        displayHelp

        exit 1
    }

    function assertValue {
        local name="$1"
        local value="${2:-}"


        if [[ -z "$value" || "$value" == -* ]]; then
            invalidArguments
        fi
    }

    local opts
    if ! opts=$(getopt -o h --long zfsDataset:,zfsDatasetOs:,zfsForksDataset:,zfsForksDatasetOs:,help -- "$@" 2>/dev/null); then
        invalidArguments
    fi
    eval set -- "$opts"

    while [[ $# -ne 0 ]]; do
        case "$1" in
            --zfsDataset)
                assertValue "$1" "$2"
                ZFS_DATASET="$2"
                shift 2
                ;;
            --zfsDatasetOs)
                assertValue "$1" "$2"
                ZFS_DATASET_OS="$2"
                shift 2
                ;;
            --zfsForksDataset)
                assertValue "$1" "$2"
                ZFS_FORKS_DATASET="$2"
                shift 2
                ;;
            --zfsForksDatasetOs)
                assertValue "$1" "$2"
                ZFS_FORKS_DATASET_OS="$2"
                shift 2
                ;;
            -h|--help) displayHelp;;
            --) shift;;
            *) invalidArguments;;
        esac
    done
}

if [[ -z "$ZFS_DATASET" ]] && { [[ -n "$ZFS_DATASET_OS" ]] || [[ -n "$VM_ZPOOL_DATASET_PARENT_FOR_OS" ]] || [[ -n "$ZFS_DATASET_OS" ]] }; then
    echo "Default ZFS dataset must be provided if any other zfs-related parameter is used"
    displayHelp
    exit 1
fi

# load configuration
source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../misc/utils.sh"
source "$SCRIPT_DIR/../misc/disks.sh"

function main {
    local VM_ZPOOL_DATASET_PARENT_FOR_GENERIC="$1"
    local VM_ZPOOL_DATASET_PARENT_FOR_OS="$2"
    local VM_ZPOOL_DATASET_FORKS_PARENT_FOR_GENERIC="${3:-$VM_ZPOOL_DATASET_PARENT_FOR_GENERIC}"
    local VM_ZPOOL_DATASET_FORKS_PARENT_FOR_OS="$4"
    local ZFS_IS_USED=""

    if [[ -z "$VM_ZPOOL_DATASET_PARENT_FOR_GENERIC" ]]; then
        echo "ZFS **NOT** used"
    else
        echo "ZFS usage enabled"
        ZFS_IS_USED="true"
    fi

    mkdir -p "$TEST_DIR"

    cat <<EOF > "$TEST_DIR/customConfig.sh"
SANAGER_TESTS_INITIALIZED="true"
ZFS_IS_USED="$ZFS_IS_USED"
VM_ZPOOL_DATASET_PARENT="$VM_ZPOOL_DATASET_PARENT_FOR_GENERIC"
VM_ZPOOL_DATASET_PARENT_FOR_GENERIC="\$VM_ZPOOL_DATASET_PARENT"
VM_ZPOOL_DATASET_PARENT_FOR_OS="$VM_ZPOOL_DATASET_PARENT_FOR_OS"

VM_ZPOOL_DATASET_FORKS_PARENT="$VM_ZPOOL_DATASET_FORKS_PARENT_FOR_GENERIC"
VM_ZPOOL_DATASET_FORKS_PARENT_FOR_GENERIC="\$VM_ZPOOL_DATASET_FORKS_PARENT"
VM_ZPOOL_DATASET_FORKS_PARENT_FOR_OS="$VM_ZPOOL_DATASET_FORKS_PARENT_FOR_OS"

USER_ME=\`whoami\`

function checkZfsPermissions {
    local DATASET="\$1"

    if ! isPathZpoolDatasetPath "\$DATASET"; then
        echo "zpool dataset path \"\$DATASET\" doesn't exist"
        exit 1
    fi

    if ! zfs allow "\$DATASET" | grep -q "\$USER_ME"; then
        echo "Missing permissions for creating sub-datasets for '\$DATASET'"
        echo "To add permissions use:"
        echo "sudo zfs allow \$USER_ME create,mount,mountpoint,destroy,volsize,volblocksize,compression,sync,primarycache,logbias,refreservation,snapshot,send,receive \$DATASET"

        exit 1
    fi
}

if [[ -n "\$ZFS_IS_USED" ]] && ! command -v zpool >/dev/null 2>&1; then
    echo "ZFS use requested, but ZFS doesn't seem to be installed"
    exit 1
fi

if [[ -n "\$VM_ZPOOL_DATASET_PARENT_FOR_GENERIC" ]]; then
    checkZfsPermissions "\$VM_ZPOOL_DATASET_PARENT_FOR_GENERIC"
fi

if [[ -n "\$VM_ZPOOL_DATASET_PARENT_FOR_OS" ]]; then
    checkZfsPermissions "\$VM_ZPOOL_DATASET_PARENT_FOR_OS"
fi

if [[ -n "\$VM_ZPOOL_DATASET_FORKS_PARENT_FOR_GENERIC" ]]; then
    checkZfsPermissions "\$VM_ZPOOL_DATASET_FORKS_PARENT_FOR_GENERIC"
fi

if [[ -n "\$VM_ZPOOL_DATASET_FORKS_PARENT_FOR_OS" ]]; then
    checkZfsPermissions "\$VM_ZPOOL_DATASET_FORKS_PARENT_FOR_OS"
fi
EOF

    echo "Sanager tests initialized"
}

parseArgs "$@"
main "$ZFS_DATASET" "$ZFS_DATASET_OS" "$ZFS_FORKS_DATASET" "$ZFS_FORKS_DATASET_OS"
