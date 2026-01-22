#!/bin/bash

# interrupt on error
set -e
#set -eu # TODO: use this to catch undefined variables
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

# load configuration
source $SCRIPT_DIR/../config.sh

# use utilities
source $SANAGER_MAIN_DIR/src/lowLevel/utilities.sh

# TODO: further refactoring
source $SCRIPT_DIR/../misc/utils.sh
source $SCRIPT_DIR/../vmBuilds/guestAdditionUtils.sh
source $SCRIPT_DIR/../vmBuilds/osInstallIsoBuilder.sh
source $SCRIPT_DIR/../vmBuilds/buildRoutines.sh
source $SCRIPT_DIR/../vmBuilds/vmBuild.sh
source $SCRIPT_DIR/../misc/sshHelpers.sh
source $SCRIPT_DIR/../misc/scenarios.sh

function main {
    local CLEAR_VMS_ON_STARTUP=false # TODO: read from parameters

    # ensure work folder exists
    mkdir -p $TEST_DIR

    # TODO: comment this out by default (create new --parameter instead)
    # clear testing VMs
    if [ $CLEAR_VMS_ON_STARTUP == true ]; then
        clearAllSanagerVms
    else
        # make sure temporary machine is gone (might have survived previous test due to script error)
        deleteVm $MACHINE_NAME_TEMPORARY
    fi

    if ! vmExists $MACHINE_NAME_BARE; then
        createTestingVm $MACHINE_NAME_BARE
        createVmDisks $MACHINE_NAME_BARE
    fi

    # VMcore build
    cachedBuildOnTopOfVm $MACHINE_NAME_BARE $MACHINE_NAME_WITH_OS vmWithOs

    cachedBuildOnTopOfVm $MACHINE_NAME_WITH_OS $MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS vmWithGuestAdditions

    # TODO: improve naming of following machins - order/hierarchy is ok, but it's naming is awful
    cachedBuildOnTopOfVm $MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS $MACHINE_NAME_TEST_BASE_PREFIX vmRunner
    cachedBuildOnTopOfVm $MACHINE_NAME_TEST_BASE_PREFIX $MACHINE_NAME_RUNNER testSanagerSetup
    cachedBuildOnTopOfVm $MACHINE_NAME_RUNNER $MACHINE_NAME_RUNNER_UNSTABLE vmRunnerUnstable

    # VM test runs

    # unstable/sid based tests
    cachedBuildOnTopOfVm $MACHINE_NAME_RUNNER_UNSTABLE $MACHINE_NAME_GRAPHICAL_DESKTOP testSanagerInstallGraphicalDesktop
    cachedBuildOnTopOfVm $MACHINE_NAME_GRAPHICAL_DESKTOP $MACHINE_NAME_PC testSanagerInstallPc

    # stable based tests
    cachedBuildOnTopOfVm $MACHINE_NAME_RUNNER $MACHINE_NAME_HOME_SERVER testSanagerInstallHomeServer
    cachedBuildOnTopOfVm $MACHINE_NAME_RUNNER $MACHINE_NAME_CRYPTO_VISUAL testSanagerCryptoVisual

    log "Tests finished successfully!"
}

# these packages should be installed (possibly via `pkg_sanager_tests_prerequisities`)
REQUIRED_PACKAGES=`listTestingDependencies`

for PACKAGE in $REQUIRED_PACKAGES; do
    if ! isInstalled $PACKAGE; then
        log "$PACKAGE package is not installed but it's required"
        exit 1
    fi
done

main
