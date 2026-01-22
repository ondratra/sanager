function __executorSsh {
    local TMP_MACHINE_NAME=$1
    local TMP_VM_USER=$2
    local TMP_VM_PASSWORD=$3
    local COMMAND=$4
    local ENV_ASSIGNMENTS=${@:5}

    runTunneledSshCommand \
        "$TMP_MACHINE_NAME" \
        $TMP_VM_USER \
        $TMP_VM_PASSWORD \
        "$ENV_ASSIGNMENTS $COMMAND"
}

# NOTE: technically the Sanager coping needs to happen just once inside of `testSanagerSetup`
#       but during debugging it's usefull to have up-to-date Sanager files available
function __copySanagerFilesToGuest {
    log "Copying Sanager folder to guest VM"
    copyTunneledSshContent \
        $TMP_MACHINE_NAME \
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
    # TODO: logs are owned by root:root and can't be cleared atm
    #clearVMLog $TMP_MACHINE_NAME "/var/log/libvirt/qemu/$TMP_MACHINE_NAME.log"

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
