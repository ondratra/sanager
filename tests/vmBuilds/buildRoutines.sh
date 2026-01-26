function tmpWait {
    # TODO: this will not work because it relies on guest additions that are yet to be installed
    # waitForVMOsBoot $TMP_MACHINE_NAME
    log Sleeping 30 seconds
    sleep 30s
    log Waking up
}

function vmWithOs {
    local TMP_MACHINE_NAME=$1

    log "Applying routine: OS to \"$TMP_MACHINE_NAME\""

    # ensure iso is available and up to date
    createCustomInstallIso

    attachDebianInstallationIso $TMP_MACHINE_NAME
    startVm $TMP_MACHINE_NAME
    waitForOsInstall $TMP_MACHINE_NAME
    stopVm $TMP_MACHINE_NAME
    deattachCd $TMP_MACHINE_NAME
}

function vmWithGuestAdditions {
    local TMP_MACHINE_NAME=$1
    local GUEST_PACKAGES="spice-vdagent qemu-guest-agent"

    log "Applying routine: GuestAdditions to \"$TMP_MACHINE_NAME\""

    __bootstrapVm "$TMP_MACHINE_NAME"

    __runTunneledCommand "apt-get update"
    __runTunneledCommand "apt-get install -y $GUEST_PACKAGES"

    grubAdaptToVmCloneHardDiskIdChanges

    stopVm $TMP_MACHINE_NAME
}

function __bootstrapVm {
    local TMP_MACHINE_NAME="$1"
    startVm $TMP_MACHINE_NAME
    tmpWait

    ensureSshRootConnection $TMP_MACHINE_NAME
}

function __runTunneledCommand {
    local COMMAND=$1
    local ENV_ASSIGNMENTS=$2

    runTunneledSshCommand "$TMP_MACHINE_NAME" $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "$COMMAND" "$ENV_ASSIGNMENTS"
}