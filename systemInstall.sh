#!/bin/bash
# see README.md for script description

# escape on error
set -e

# output all commands done if debug mode is on
if [[ "$DEBUG" == "true" ]]; then
    set -x
fi

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

# used when importing ubuntu packages
NOWADAYS_UBUNTU_VERSION="lunar"
NOWADAYS_DEBIAN_VERSION="bullseye"
TARGET_DEBIAN_VERSION="sid"
SANAGER_MAIN_DIR="/opt/__sanager"
SANAGER_INSTALL_DIR="$SANAGER_MAIN_DIR/install"
SANAGER_INSTALL_TEMP_DIR="$SANAGER_MAIN_DIR/tmp"
SANAGER_GPG_KEY_DIR="$SANAGER_MAIN_DIR/gpgKeys"

SCRIPT_EXECUTING_USER=$SUDO_USER
SCRIPT_DIR="`echo $(dirname $(readlink -nf $0))`"
SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized

VERBOSE_SCRIPT=`[[ "$2" == "--verbose" ]] && echo 1 || echo 0`
VERBOSE_APT_FLAG=`[[ "$VERBOSE_SCRIPT" == "1" ]] && echo "" || echo "-qq"`
VERBOSE_WGET_FLAG=`[[ "$VERBOSE_SCRIPT" == "0" ]] && echo "" || echo "-q"`

# for detection info see http://www.dmo.ca/blog/detecting-virtualization-on-linux/
TMP=`dmesg | grep -i virtualbox || echo ""`
IS_VIRTUALBOX_GUEST=`[[ "$TMP" == "" ]] && echo 0 || echo 1`


source $SCRIPT_DIR/src/lowLevel/utilities.sh


###############################################################################
# Definitions of functions installing system components
###############################################################################

source $SCRIPT_DIR/src/lowLevel/cookbook.sh


###############################################################################
# Main procedure
###############################################################################

function printExistingBlueprints {
    echo "Existing blueprints:"
    ls $SCRIPT_DIR/src/highLevel | while read tmpFilename
    do
        echo "    ${tmpFilename%%.*}"
    done
}

if [[ $# -eq 0 ]]; then
    echo "Invalid parameter count."
    echo "Select installation blueprint in first parameter. (For example \"pc\")"
    printExistingBlueprints
    exit 1;
fi

BLUEPRINT_PATH="$SCRIPT_DIR/src/highLevel/$1.sh"
if [[ ! -f $BLUEPRINT_PATH ]]; then
    echo "Installation blueprint \"$1\" not found."
    printExistingBlueprints
    exit 1;
fi

source $BLUEPRINT_PATH
# TODO: uncomment this when guest additions are used again
#virtualboxGuest # always try to install virtualbox guest features (will have no effect in non-virtualized environments)
runHighLevel "${@:2}"


###############################################################################
# Post run cleansing
###############################################################################

# make sure all dependencies are met and remove any unused packages
printMsg "Cleaning up"
distCleanup
