# interrupt on error
set -e
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

if [[ $# -ne 3 ]]; then
    echo "Fork existing VM"
    echo "Usage:"
    echo "$0 ORIGINAL_NAME CLONE_NAME TARGET_DIR"
    echo "Example:"
    echo "$0 Sanager_Temporary Sanager_MySpecificUse /path/to/virtual/machines"

    exit 1;
fi

source $SCRIPT_DIR/../config.sh
source $SCRIPT_DIR/../misc/utils.sh

forkVm $1 $2 $3
