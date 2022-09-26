function tmpWait {
    # TODO: this will not work because it relies on guest additions that are yet to be installed
    # waitForVMOsBoot $TMP_MACHINE_NAME
    log Sleeping 40 seconds
    sleep 40s
    log Waking up
}

function vmWithOs {
    local TMP_MACHINE_NAME=$1

    log "Applying routine: OS"

    # TODO: "run VM with custom install iso"

    # TODO
    # downloadInstallMedium
    # createCustomInstallIso

    # TODO: enable ssh connection for root user
    # sudo apt-get install openssh-server
    # sudo sed -i -r "s~#PermitRootLogin [-a-z]+~PermitRootLogin yes~g" /etc/ssh/sshd_config
    # sudo sed -i -r "s~#PasswordAuthentication yes~PasswordAuthentication yes~g" /etc/ssh/sshd_config
    # sudo ssh-keygen -A # ensure mandatory ssh server folders and files exist
    # sudo systemctl restart sshd

    # TODO: make sure repositories are updated; needed for essential packages to be installed
    # sudo -E ./systemInstall lowLevel distUpgrade (how to call it before Sanager folder is rsynced??)
    # sudo -E ./systemInstall lowLevel distCleanup (how to call it before Sanager folder is rsynced??)
}

function vmWithGuestAdditions {
    local TMP_MACHINE_NAME=$1

    log "Applying routine: GuestAdditions to `$TMP_MACHINE_NAME`"

    startVm $TMP_MACHINE_NAME
    tmpWait

    ensureSshRootConnection $TMP_MACHINE_NAME

    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "mkdir /mnt/tmp"
    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "mount /dev/sr1 /mnt/tmp"
    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "apt-get update"
    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "apt-get install -y linux-headers-\$(uname -r) build-essential dkms"

    # VBoxLinuxAdditions.run exists with code `2` on what it's consider as success here
    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "/mnt/tmp/VBoxLinuxAdditions.run --nox11 || true"

    stopVm $TMP_MACHINE_NAME
}

function vmRunner {
    local TMP_MACHINE_NAME=$1

    log "Applying routine: Runner"

    # share Sanager to guest VM
    vmShareFolder $TMP_MACHINE_NAME $SANAGER_MAIN_DIR $SANAGER_GUEST_FOLDER_NAME

    startVm $TMP_MACHINE_NAME
    tmpWait

    ensureSshRootConnection $TMP_MACHINE_NAME

    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "apt-get update"
    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "apt-get install -y rsync"

    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD "usermod -a -G vboxsf $VM_USERS_SANAGER_NAME"

    stopVm $TMP_MACHINE_NAME
}

