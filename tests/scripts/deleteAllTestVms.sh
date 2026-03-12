# interrupt on error
set -e

SCRIPT_DIR="`dirname \"$0\"`" # relative

source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../misc/utils.sh"

requireTestConfigInit
source "$TEST_DIR/customConfig.sh"
source "$SCRIPT_DIR/../misc/disks.sh"

clearAllSanagerVms
