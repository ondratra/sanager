function tmpWait {
    # TODO: this will not work because it relies on guest additions that are yet to be installed
    # waitForVMOsBoot $TMP_MACHINE_NAME
    log Sleeping 40 seconds
    sleep 40s
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

    log "Applying routine: GuestAdditions to \"$TMP_MACHINE_NAME\""

    attachVBoxGuestAdditions $TMP_MACHINE_NAME
    __bootstrapVm

    __runTunneledCommand "mkdir /mnt/tmp"
    __runTunneledCommand "mount /dev/sr0 /mnt/tmp"
    __runTunneledCommand "apt-get update"
    # TODO: `linux-headers-\$(uname -r)` can throw error if previous machine has old kernel that is no longer available
    #       in repositories. Rethink this approach.
    __runTunneledCommand "apt-get install -y linux-headers-\$(uname -r) build-essential dkms" "DEBIAN_FRONTEND=noninteractive"

    # VBoxLinuxAdditions.run exists with code `2` which is considered as success here
    __runTunneledCommand "/mnt/tmp/VBoxLinuxAdditions.run --nox11 || true"

    grubAdaptToVmCloneHardDiskIdChanges

    stopVm $TMP_MACHINE_NAME
    deattachCd $TMP_MACHINE_NAME
}

function vmRunner {
    local TMP_MACHINE_NAME=$1

    log "Applying routine: Runner"

    # share Sanager to guest VM
    vmShareFolder "$TMP_MACHINE_NAME" "$SANAGER_MAIN_DIR" "$SANAGER_GUEST_FOLDER_NAME" "$SANAGER_GUEST_SHARED_FOLDER_PATH"

    __bootstrapVm

    __runTunneledCommand "apt-get update"
    __runTunneledCommand "apt-get install -y rsync" "DEBIAN_FRONTEND=noninteractive"

    __runTunneledCommand "usermod -a -G vboxsf $VM_USERS_SANAGER_NAME"

    stopVm $TMP_MACHINE_NAME
}

function vmRunnerUnstable {
    local TMP_MACHINE_NAME=$1

    log "Applying routine: Runner unstable"

    __bootstrapVm

    __runTunneledCommand "$SANAGER_GUEST_FOLDER_PATH/utilities/changeDebianToSid.sh"
    __runTunneledCommand "apt-get update"
    __runTunneledCommand "apt-get dist-upgrade -y" "DEBIAN_FRONTEND=noninteractive"

    stopVm $TMP_MACHINE_NAME
}

function __bootstrapVm {
    startVm $TMP_MACHINE_NAME
    tmpWait

    ensureSshRootConnection $TMP_MACHINE_NAME
}

function __runTunneledCommand {
    local COMMAND=$1
    local ENV_ASSIGNMENTS=$2

    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "$COMMAND" "$ENV_ASSIGNMENTS"
}