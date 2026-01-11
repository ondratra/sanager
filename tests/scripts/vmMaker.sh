# interrupt on error
set -e
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

if [[ $# -lt 5 ]]; then
    echo "Fork existing VM"
    echo "Usage:"
    echo "$0 ORIGINAL_NAME CLONE_NAME SSH_SERVER_PORT VRDE_PORT TARGET_DIR"
    echo "Example:"
    echo "$0 Sanager_Temporary Sanager_MySpecificUse 2223 10002 /path/to/virtual/machines"

    exit 1;
fi

source $SCRIPT_DIR/../config.sh
source $SCRIPT_DIR/../misc/utils.sh

forkVm $1 $2 $3 $4 $5
