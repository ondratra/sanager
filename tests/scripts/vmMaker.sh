# interrupt on error
set -e
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

source "$SCRIPT_DIR/../config.sh"

if [[ $# -ne 3 ]]; then
    echo "Fork existing VM"
    echo "Usage:"
    echo "$0 ORIGINAL_NAME CLONE_NAME VM_TYPE"
    echo "Example:"
    echo "$0 Sanager_Temporary Sanager_MySpecificUse GENERIC"
    echo "Supported VM_TYPE: $ZFS_ZVOL_ARCHITECTURES"

    exit 1;
fi

source "$SCRIPT_DIR/../misc/utils.sh"

requireTestConfigInit
source "$TEST_DIR/customConfig.sh"
source "$SCRIPT_DIR/../misc/disks.sh"

detectMissingAccessToTestingFolder "$TEST_DIR"

ORIGINAL_NAME="$1"
# NOTE: due to missing group/tag feature in virt-manager, let's prefix VM name to distinguish it
FORK_NAME="${FORK_NAME_PREFIX}${2}"
VM_TYPE="$3"

if vmExists "$FORK_NAME"; then
    echo "Fork already exists. Overwrite is not supported. Delete it manually first or choose a different name."
    exit 1
fi

forkVm "$ORIGINAL_NAME" "$FORK_NAME" "$VM_TYPE"
