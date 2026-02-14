EXECUTOR=__executorSsh

# TODO: deduplicate common code of sanager high level install

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
    __executeCommand "echo $VM_USERS_SANAGER_PASSWORD | sudo -ES /bin/bash $SANAGER_GUEST_FOLDER_PATH/systemInstall.sh lowLevel aptDistUpgradeTolerateBugs"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}

function testSanagerInstallTerminal {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "Terminal" terminal
}

function testSanagerInstallGraphicalDesktop {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "Graphical Desktop" graphicalDesktop
}

function testSanagerInstallPc {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "PC" pc
}

function testSanagerInstallPhysicalPc {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "Physical PC" physicalPc
}

function testSanagerInstallHomeServerTerminal {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "Home Server Terminal" homeServerTerminal
}

function testSanagerInstallHomeServerGraphical {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "Home Server Graphical" homeServerGraphical
}

function testSanagerInstallCryptoVisual {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "Crypto Visual" cryptoVisual
}

function testSanagerInstallGeneralUseVps {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "General Use VPS" generalUseVps
}

function testSanagerInstallAiCore {
    local TMP_MACHINE_NAME=$1

    sanagerStateInstall "$TMP_MACHINE_NAME" "AI core" aiCore
}

function sanagerStateInstall {
    local TMP_MACHINE_NAME="$1"
    local HUMAN_READABLE_NAME="$2"
    local HIGH_LEVEL_TARGET="$3"

    log "Running Sanager install on $TMP_MACHINE_NAME - $HUMAN_READABLE_NAME"

    __startupVm
    __copySanagerFilesToGuest

    log "Running Sanager script: \`systemInstall.sh HIGH_LEVEL_TARGET\`"
    __executeCommand "echo $VM_USERS_SANAGER_PASSWORD | sudo -ES /bin/bash $SANAGER_GUEST_FOLDER_PATH/systemInstall.sh $HIGH_LEVEL_TARGET"

    __syncFileSystem

    stopVm $TMP_MACHINE_NAME
}
