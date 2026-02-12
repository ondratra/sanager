#!/bin/bash

# interrupt on error
set -e
#set -eu # TODO: use this to catch undefined variables
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative

# load configuration
source "$SCRIPT_DIR/../config.sh"

# use utilities
source "$SANAGER_MAIN_DIR/src/lowLevel/utilities.sh"

source "$SCRIPT_DIR/../misc/utils.sh"
source "$SCRIPT_DIR/../vmBuilds/guestAdditionUtils.sh"
source "$SCRIPT_DIR/../vmBuilds/osInstallIsoBuilder.sh"
source "$SCRIPT_DIR/../vmBuilds/buildRoutines.sh"
source "$SCRIPT_DIR/../vmBuilds/vmBuild.sh"
source "$SCRIPT_DIR/../misc/sshHelpers.sh"
source "$SCRIPT_DIR/../misc/scenarios.sh"

function main {
    # ensure work folder exists
    mkdir -p $TEST_DIR

    detectMissingAccessToTestingFolder "$TEST_DIR"

    # make sure temporary machine is gone (might have survived previous test due to script error)
    deleteVm "$MACHINE_NAME_TEMPORARY"

    if ! vmExists "$MACHINE_NAME_BARE"; then
        createTestingVm "$MACHINE_NAME_BARE"
        createVmDisks "$MACHINE_NAME_BARE"
    fi

    # VM core build
    cachedBuildOnTopOfVm "$MACHINE_NAME_BARE" "$MACHINE_NAME_WITH_OS" vmWithOs
    cachedBuildOnTopOfVm "$MACHINE_NAME_WITH_OS" "$MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS" vmWithGuestAdditions
    cachedBuildOnTopOfVm "$MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS" "$MACHINE_NAME_STABLE_WITH_SANAGER" testSanagerSetup

    buildStableBasedVms
    buildUnstableBasedVms

    log "Tests finished successfully!"
}

function buildStableBasedVms {
    # VM minimals - terminal-only/graphics
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_WITH_SANAGER" "$MACHINE_NAME_STABLE_TERMINAL_BASE" testSanagerInstallTerminal
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_TERMINAL_BASE" "$MACHINE_NAME_STABLE_GRAPHICAL_BASE" testSanagerInstallGraphicalDesktop

    # stable-based tests
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_TERMINAL_BASE" "$MACHINE_NAME_STABLE_HOME_SERVER_TERMINAL" testSanagerInstallHomeServerTerminal
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_GRAPHICAL_BASE" "$MACHINE_NAME_STABLE_HOME_SERVER_GRAPHICAL" testSanagerInstallHomeServerGraphical
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_GRAPHICAL_BASE" "$MACHINE_NAME_STABLE_CRYPTO_VISUAL" testSanagerInstallCryptoVisual
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_TERMINAL_BASE" "$MACHINE_NAME_STABLE_GENERAL_USE_VPS" testSanagerInstallGeneralUseVps
}

function buildUnstableBasedVms {
    # VM minimals - terminal-only/graphics
    cachedBuildOnTopOfVm "$MACHINE_NAME_STABLE_TERMINAL_BASE" "$MACHINE_NAME_UNSTABLE_BASE" testSanagerSwitchToUnstable
    cachedBuildOnTopOfVm "$MACHINE_NAME_UNSTABLE_BASE" "$MACHINE_NAME_UNSTABLE_TERMINAL_BASE" testSanagerInstallTerminal # reapply highLevel "terminal" this will update kernel for example
    cachedBuildOnTopOfVm "$MACHINE_NAME_UNSTABLE_TERMINAL_BASE" "$MACHINE_NAME_UNSTABLE_GRAPHICAL_BASE" testSanagerInstallGraphicalDesktop

    # unstable-based tests
    cachedBuildOnTopOfVm "$MACHINE_NAME_UNSTABLE_GRAPHICAL_BASE" "$MACHINE_NAME_UNSTABLE_PC" testSanagerInstallPc
    cachedBuildOnTopOfVm "$MACHINE_NAME_UNSTABLE_GRAPHICAL_BASE" "$MACHINE_NAME_UNSTABLE_PHYSICAL_PC" testSanagerInstallPhysicalPc
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
