
function log {
    echo "SANAGER TESTS: $@"
}

function downloadInstallMedium {
    if [[ -f $NETINSTALL_ISO_FILE ]]; then
        return
    fi

    wgetDownload $NETINSTALL_ISO_URL -O $NETINSTALL_ISO_FILE
}

function clearVMLog {
    local TMP_MACHINE_NAME=$1
    LOG_FILE=$2

    # clear log
    if [ -f $LOG_FILE ]; then
        echo "" > $LOG_FILE
    fi
}

function startVm {
    local TMP_MACHINE_NAME=$1

    log "Starting VM \"$TMP_MACHINE_NAME\""

    VBoxManage startvm $TMP_MACHINE_NAME
}

function stopVm {
    local TMP_MACHINE_NAME=$1

    log "Stopping VM \"$TMP_MACHINE_NAME\""

    VBoxManage controlvm $TMP_MACHINE_NAME poweroff

    # TODO: revisit this - without sleep VM tends to be still locked when starting
    sleep 3
}

function restartVm {
    local TMP_MACHINE_NAME=$1

    log "Restarting VM \"$TMP_MACHINE_NAME\""

    stopVm $TMP_MACHINE_NAME

    # TODO: revisit this - without sleep VM tends to be still locked when starting
    sleep 3

    startVm $TMP_MACHINE_NAME
}

function isVMBooted {
    local TMP_MACHINE_NAME=$1

    log "Checking if VM is booted"

    #__isVMBootedGuestAdditions $TMP_MACHINE_NAME
    __isVMBootedSsh $TMP_MACHINE_NAME
}

function __isVMBootedGuestAdditions {
    # NOTE: this currently doesn't fully work because current Virtualbox guest additions don't work properly
    #       Debian package `virtualbox-guest-additions-iso` - versions tried: `6.1.36-1`, `6.1.38-1`
    log "Can't check that VM is booted this way - guest additions not working"
    exit 1

    local TMP_MACHINE_NAME=$1

    # decide if VM is booted by looking into VM log and search for shared folder mount event
    local LOG_FILE=$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME/Logs/VBox.log
    local LOG_SUCCESS_MESSAGE="Successfully mounted 'sanager' on '/media/sf_sanager'"

    # TODO: return value
    grep "$LOG_SUCCESS_MESSAGE" "$LOG_FILE" 2> /dev/null || PROBLEM=$?
}

function __isVMBootedSsh {
    local TMP_MACHINE_NAME=$1

    ensureSshRootConnection $TMP_MACHINE_NAME

    SSH_PING_RESULT=$?

    return $SSH_PING_RESULT
}

# TODO: improve mechanism that recognizes booted OS
# this function needs clearVMLog to be called before starting VM
function waitForVMOsBoot {
    local TMP_MACHINE_NAME=$1

    log "Starting waiting for guest VM to boot OS"

    while true; do
        PROBLEM="0"

        isVMBooted $TMP_MACHINE_NAME || PROBLEM=$?

        if [[ "$PROBLEM" == "0" ]]; then
            break
        fi

        sleep 1

        log "Waiting for VM \"$TMP_MACHINE_NAME\"'s OS to boot"
    done

    ## TODO: remove
    #echo "safety sleep"
    #sleep 10 # safety sleep
}

function cloneVM {
    local ORIGINAL_NAME=$1
    local CLONE_NAME=$2

    log "Cloning VM $ORIGINAL_NAME -> $CLONE_NAME"

    VBoxManage clonevm $ORIGINAL_NAME \
        --register \
        --options=KeepDiskNames,KeepHwUUIDs \
        --name $CLONE_NAME \
        --basefolder $VIRTUAL_MACHINES_DIR
}

function deleteVm {
    local TMP_MACHINE_NAME=$1

    log "Deleting VM \"$TMP_MACHINE_NAME\""

    VBoxManage unregistervm --delete $TMP_MACHINE_NAME 2> /dev/null || true
}

function clearAllSanagerVms {
    log "Clearing all existing VMs"

    deleteVm $MACHINE_NAME_TEMPORARY
    deleteVm $MACHINE_NAME_BARE
    deleteVm $MACHINE_NAME_WITH_OS
    deleteVm $MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS
    deleteVm "${MACHINE_NAME_TEST_PREFIX}1" # TODO

    rm -rf $VIRTUAL_MACHINES_DIR
}

function vmExists {
    local TMP_MACHINE_NAME=$1
    local PROBLEM="0"

    VBoxManage showvminfo $TMP_MACHINE_NAME > /dev/null 2> /dev/null || PROBLEM=$?

    if [[ "$PROBLEM" == "0" ]]; then
        echo "0"
        return
    fi

    echo "1"
}


function ensureSshRootConnection {
    local TMP_MACHINE_NAME=$1

    runTunneledSshCommand $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD exit

    # if ssh connection can't be estabilished, previous command fails;
    # thus, ssh connection is ensured at this point
}

function runTunneledSshCommand {
    local TMP_USER=$1
    local TMP_PASSWORD=$2
    local TMP_COMMAND=$3

    # ensure no conflict between VM saved and current fingerprints
    __clearSshFingerprint

    log "Running command through ssh. \`$TMP_COMMAND\`"

    sshpass \
        -p $TMP_PASSWORD \
        ssh $TMP_USER@$SSH_TUNNEL_HOST_HOSTNAME \
            -p $SSH_TUNNEL_HOST_PORT \
            -o ConnectTimeout=5 \
            -o PubkeyAuthentication=no \
            -o "StrictHostKeyChecking=accept-new" \
            "$TMP_COMMAND"
}

function copyTunneledSshContent {
    local TMP_USER=$1
    local TMP_PASSWORD=$2
    local TMP_LOCAL_FILEPATH=$3
    local TMP_REMOTE_FILEPATH=$4
    local TMP_EXCLUDED_PATHS=$5

    local EXCLUDED_PARAMETER=${TMP_EXCLUDED_PATHS:+"--exclude=$TMP_EXCLUDED_PATHS"}

    log "Copying files over SSH \"$TMP_LOCAL_FILEPATH\" -> \"$TMP_REMOTE_FILEPATH\" ($EXCLUDED_PARAMETER)"

    # ensure no conflict between VM saved and current fingerprints
    __clearSshFingerprint

    rsync \
        --progress \
        -avz \
        -e "sshpass \
            -p $TMP_PASSWORD \
            ssh \
                -p $SSH_TUNNEL_HOST_PORT \
                -o ConnectTimeout=5 \
                -o PubkeyAuthentication=no \
                -o StrictHostKeyChecking=accept-new \
        " \
        $EXCLUDED_PARAMETER \
        "$TMP_LOCAL_FILEPATH" "$TMP_USER@$SSH_TUNNEL_HOST_HOSTNAME:$TMP_REMOTE_FILEPATH"
}

# remove any fingerprints for the host as it may come from different VM with same ssh tunnel setup
function __clearSshFingerprint {
    log "Clearing SSH fingerprint (if exists)"

    ssh-keygen -R [$SSH_TUNNEL_HOST_HOSTNAME]:$SSH_TUNNEL_HOST_PORT
}
