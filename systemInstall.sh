#!/bin/bash
# see README.md for script description

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
NOWADAYS_UBUNTU_VERSION="xenial"
SANAGER_INSTALL_DIR="/opt/sanagerInstall"

SCRIPT_EXECUTING_USER=$SUDO_USER
SCRIPT_DIR="`dirname \"$0\"`" # relative
SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized

VERBOSE_SCRIPT=`[[ "$1" == "--verbose" ]] && echo 1 || echo 0`
VERBOSE_APT_FLAG=`[[ "$VERBOSE_SCRIPT" == "1" ]] && echo "" || echo "-qq"`
VERBOSE_WGET_FLAG=`[[ "$VERBOSE_SCRIPT" == "0" ]] && echo "" || echo "-q"`

# for detection info see http://www.dmo.ca/blog/detecting-virtualization-on-linux/
TMP=`dmesg | grep -i virtualbox`
IS_VIRTUALBOX_GUEST=`[[ "$TMP" == "" ]] && echo 0 || echo 1`


source ./utilities.sh

###############################################################################
# Definitions of functions installing system components
###############################################################################

source ./cookbook.sh


###############################################################################
# Main procedure
###############################################################################

essential
#desktopDisplayEtc
#
desktopDisplayEtc
ininalityFonts
networkManager
#
virtualboxGuest
#userEssential
#
userEssential
enableHistorySearch
enableBashCompletion
restoreMateConfig
dropbox
#
#work
#
work
sublimeText
nodejs
yarnpkg
lamp
openvpn
obsStudio
rabbitVCS
unity3d
#
#fun
#
multimedia
steam
rhythmbox
playOnLinux
#


###############################################################################
# Post run cleansing
###############################################################################

apt-get $VERBOSE_APT_FLAG -f install # make sure all dependencies are met
apt-get $VERBOSE_APT_FLAG autoremove # remove any unused packages
