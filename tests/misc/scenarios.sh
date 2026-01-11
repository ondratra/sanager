EXECUTOR=__executorSsh

function testSanagerSetup {
    local TMP_MACHINE_NAME=$1

    log "Running Sanager setup on $TMP_MACHINE_NAME"

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

################### Helpers ####################################################

function __executorSsh {
    local TMP_MACHINE_NAME=$1
    local TMP_VM_USER=$2
    local TMP_VM_PASSWORD=$3
    local COMMAND=$4
    local ENV_ASSIGNMENTS=${@:5}

    runTunneledSshCommand \
        $TMP_VM_USER \
        $TMP_VM_PASSWORD \
        "$ENV_ASSIGNMENTS $COMMAND"
}

function __executorGuestAdditions {
    # NOTE: this currently doesn't fully work because current Virtualbox guest additions don't work properly
    #       Debian package `virtualbox-guest-additions-iso` - versions tried: `6.1.36-1`, `6.1.38-1`
    log "Can't run install routine this way - guest additions not working"
    exit 1

    local TMP_MACHINE_NAME=$1
    local TMP_VM_USER=$2
    local TMP_VM_PASSWORD=$3
    local COMMAND=$4
    local ENV_ASSIGNMENTS=${@:5}

    # TODO: set requested username/password
    vmExecShellCommand "$COMMAND" $ENV_ASSIGNMENTS
}

# NOTE: technically the Sanager coping needs to happen just once inside of `testSanagerSetup`
#       but during debugging it's usefull to have up-to-date Sanager files available
function __copySanagerFilesToGuest {
    log "Copying Sanager folder to guest VM"
    copyTunneledSshContent \
        $VM_USERS_SANAGER_NAME \
        $VM_USERS_SANAGER_PASSWORD \
        $SANAGER_MAIN_DIR \
        `dirname $SANAGER_GUEST_FOLDER_PATH` \
        ".*"
}

function __syncFileSystem {
    log "Syncing file system"
    $EXECUTOR \
        $TMP_MACHINE_NAME \
        $VM_USERS_ROOT_NAME \
        $VM_USERS_ROOT_PASSWORD \
        "/bin/sync"
}

function __startupVm {
    # TODO: try to get rid of this call by improving wairForVMOsBoot
    clearVMLog $TMP_MACHINE_NAME "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME/Logs/VBox.log"

    # startup VM
    startVm $TMP_MACHINE_NAME
    waitForVMOsBoot $TMP_MACHINE_NAME
}

function __executeCommand {
    local COMMAND=$1
    local ENV_ASSIGNMENTS=$2

    $EXECUTOR \
        $TMP_MACHINE_NAME \
        $VM_USERS_SANAGER_NAME \
        $VM_USERS_SANAGER_PASSWORD \
        "$COMMAND" \
        "$ENV_ASSIGNMENTS"
}

function __executeCommandAsRoot {
    local COMMAND=$1
    local ENV_ASSIGNMENTS=$2

    $EXECUTOR \
        $TMP_MACHINE_NAME \
        $VM_USERS_ROOT_NAME \
        $VM_USERS_ROOT_PASSWORD \
        "$COMMAND" \
        "$ENV_ASSIGNMENTS"
}
