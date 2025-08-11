#!/bin/bash

###############################################################################
# Permission lock - only regular user using `sude -E` is allowed
###############################################################################

if [[ "$SUDO_USER" == "" ]]; then
    TMP='`sudo -E '$0'`'
    echo "You should run this script as regular user. Run: $TMP"
    echo "It's the only way to use your ssh keys for git auth, etc."
    exit 1;
fi


###############################################################################
# Settings and helpers
###############################################################################

source ./utilities/exportMateConfig.sh
source ./utilities/exportSublimeTextConfig.sh

SUBLIME_TEXT_PACKAGE_LOCAL_NAME="Ondratra"

SCRIPT_DIR="`dirname \"$0\"`" # relative
SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized

###############################################################################
# Main procedure
###############################################################################

echo "SANAGER: exporting configuration to Sanager folder";
exportMateConfig
exportSublimeTextConfig
