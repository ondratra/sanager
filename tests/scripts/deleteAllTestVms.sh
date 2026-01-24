# interrupt on error
set -e

SCRIPT_DIR="`dirname \"$0\"`" # relative

source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../misc/utils.sh"

clearAllSanagerVms
