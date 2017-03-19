#!/bin/bash

###############################################################################
# Permission lock - only root user is allowed
###############################################################################

# 1>&2 # write to stderr
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


###############################################################################
# Argument check
###############################################################################

TMP_USERNAME=`id -u "$NON_ROOT_USERNAME" 2> /dev/null`
if [[ $TMP_USERNAME == "" ]] || [[ $TMP_USERNAME == "root" ]]; then
   echo "You must provide you regular user's username via NON_ROOT_USERNAME" 1>&2
   exit 1
fi


###############################################################################
# Main procedure
###############################################################################

# acting as root run
echo "SANAGER: Updating apt cache and installing sudo package";
apt-get update -qq
apt-get install sudo -qq
echo "SANAGER: Adding user $NON_ROOT_USERNAME privileges to sudo. (relogin on all terminals to make effect)";
adduser $NON_ROOT_USERNAME sudo
