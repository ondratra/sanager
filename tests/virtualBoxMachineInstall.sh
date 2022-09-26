#!/bin/bash
#exit 1 # don't run this script yet

# TODO:
# netinstall - https://wiki.debian.org/PXEBootInstall
# create custom install cd (?) - https://www.librebyte.net/en/systems-deployment/unattended-debian-installation/

# TODO:
# `VBoxManage guestcontrol MACHINE_XXX run` doesn't work properly so SSH connection has to be used instead which has
# its own caveats.

# interrupt on error
set -e
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

# load configuration
source $SCRIPT_DIR/config.sh

# use utilities
source $SANAGER_MAIN_DIR/src/lowLevel/utilities.sh

# TODO: further refactoring
source $SCRIPT_DIR/utils.sh
source $SCRIPT_DIR/guestAdditionUtils.sh
source $SCRIPT_DIR/osInstallIsoBuilder.sh
source $SCRIPT_DIR/buildRoutines.sh
source $SCRIPT_DIR/vmBuild.sh
source $SCRIPT_DIR/scenarios.sh

function main {
    local TEST_NUMBER=1 # TODO
    local CLEAR_VMS_ON_STARTUP=false # TODO: read from parameters

    local MACHINE_RUNNER_NAME="${MACHINE_NAME_TEST_PREFIX}${TEST_NUMBER}"

    # ensure work folder exists
    mkdir -p $TEST_DIR

    # TODO: comment this out by default (create new --parameter instead)
    # clear testing VMs
    if [ CLEAR_VMS_ON_STARTUP == true ]; then
        clearAllSanagerVms
    else
        echo cleaning tmp
        # make sure temporary machine is gone (might have survived previous test due to script error)
        deleteVm $MACHINE_NAME_TEMPORARY
    fi

    # create VM
    if [[ `vmExists $MACHINE_NAME_BARE` != "0" ]]; then
        createTestingVm $MACHINE_NAME_BARE
        createVmDisks $MACHINE_NAME_BARE
    fi

    # VMcore build

    cachedBuildOnTopOfVm $MACHINE_NAME_BARE $MACHINE_NAME_WITH_OS vmWithOs

    cachedBuildOnTopOfVm $MACHINE_NAME_WITH_OS $MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS vmWithGuestAdditions

    cachedBuildOnTopOfVm $MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS $MACHINE_RUNNER_NAME vmRunner

    # VM test runs

    local MACHINE_NAME_ROOT_INSTALL=${MACHINE_RUNNER_NAME}_rootInstall
    local MACHINE_NAME_GRAPHICAL_DESKTOP=${MACHINE_RUNNER_NAME}_graphicalDesktop
    local MACHINE_NAME_PC=${MACHINE_RUNNER_NAME}_pc

    cachedBuildOnTopOfVm $MACHINE_RUNNER_NAME $MACHINE_NAME_ROOT_INSTALL testSanagerSetup
    cachedBuildOnTopOfVm $MACHINE_NAME_ROOT_INSTALL $MACHINE_NAME_GRAPHICAL_DESKTOP testSanagerInstallGraphicalDesktop
    cachedBuildOnTopOfVm $MACHINE_NAME_GRAPHICAL_DESKTOP $MACHINE_NAME_PC testSanagerInstallPc

    log "Tests finished successfully!"
}

# ensure Virtual box manager is available
if ! command -v VBoxManage &> /dev/null
then
    log "VBoxManage could not be found but it's required"
    exit 1
fi

REQUIRED_PACKAGES="curlftpfs virtualbox-guest-additions-iso openssh-client rsync"

for PACKAGE in $REQUIRED_PACKAGES; do
    if ! isInstalled $PACKAGE; then
        log "$PACKAGE package is not installed but it's required"
        exit 1
    fi
done

main
