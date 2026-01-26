EXECUTOR=__executorSsh

function testSanagerSetup {
    local TMP_MACHINE_NAME=$1

    log "Running Sanager setup on $TMP_MACHINE_NAME"

    vmShareFolder "$TMP_MACHINE_NAME" "$SANAGER_MAIN_DIR" "$SANAGER_GUEST_FOLDER_NAME" "$SANAGER_GUEST_FOLDER_SHARED_PATH"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`rootInit.sh\`"
    __executeCommandAsRoot \
        "/bin/bash \"$SANAGER_GUEST_FOLDER_PATH/rootInit.sh\"" \
        "NON_ROOT_USERNAME=$VM_USERS_SANAGER_NAME AUTO_ACCEPT_FLAG=-y"

    # don't repeat /bin/sync call code over and over again - create meaningful function
    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function testSanagerSwitchToUnstable {
    local TMP_MACHINE_NAME=$1

    log "Running Sanager switch to unstable on $TMP_MACHINE_NAME"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`utilities/changeDebianToSid.sh\`"
    __executeCommandAsRoot "/bin/bash \"$SANAGER_GUEST_FOLDER_PATH/utilities/changeDebianToSid.sh\""

    __executeCommandAsRoot "apt-get update"
    __executeCommandAsRoot "apt-get dist-upgrade -y" "DEBIAN_FRONTEND=noninteractive"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function testSanagerInstallGraphicalDesktop {
    local TMP_MACHINE_NAME=$1

    log "Running Sanager install on $TMP_MACHINE_NAME - Graphical Desktop"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`systemInstall.sh graphicalDesktop\`"
    __executeCommand "echo $VM_USERS_SANAGER_PASSWORD | sudo -ES /bin/bash $SANAGER_GUEST_FOLDER_PATH/systemInstall.sh graphicalDesktop"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function testSanagerInstallPc {
    local TMP_MACHINE_NAME=$1

    log "Running Sanager install on $TMP_MACHINE_NAME - PC"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`systemInstall.sh pc\`"
    __executeCommand "echo $VM_USERS_SANAGER_PASSWORD | sudo -ES /bin/bash $SANAGER_GUEST_FOLDER_PATH/systemInstall.sh pc"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function testSanagerInstallHomeServer {
    local TMP_MACHINE_NAME=$1

    # ensure root install
    #testSanagerSetup $TMP_MACHINE_NAME

    log "Running Sanager install on $TMP_MACHINE_NAME - HomeServer"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`systemInstall.sh homeServer\`"
    __executeCommand "echo $VM_USERS_SANAGER_PASSWORD | sudo -ES /bin/bash $SANAGER_GUEST_FOLDER_PATH/systemInstall.sh homeServer"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function testSanagerCryptoVisual {
    local TMP_MACHINE_NAME=$1

    log "Running Sanager install on $TMP_MACHINE_NAME - PC"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`systemInstall.sh cryptoVisual\`"
    __executeCommand "echo $VM_USERS_SANAGER_PASSWORD | sudo -ES /bin/bash $SANAGER_GUEST_FOLDER_PATH/systemInstall.sh cryptoVisual"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function runSanagerGuestVMChecks {
    local TMP_MACHINE_NAME=$1

    # TODO
    echo "TODO"

    # TODO: "run sanager checks"
}
