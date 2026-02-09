
function log {
    echo "SANAGER TESTS: $@"
}

function downloadInstallMedium {
    if [[ -f $NETINSTALL_ORIGINAL_ISO_FILE ]]; then
        return
    fi

    wgetDownload $NETINSTALL_ISO_URL -O $NETINSTALL_ORIGINAL_ISO_FILE
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

    virsh start "$TMP_MACHINE_NAME"
}

function stopVm {
    local TMP_MACHINE_NAME=$1

    log "Stopping VM \"$TMP_MACHINE_NAME\""

    virsh shutdown "$TMP_MACHINE_NAME"

    # TODO: revisit this - without sleep VM tends to be still locked when starting
    virsh domstate "$TMP_MACHINE_NAME" >/dev/null 2>&1
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

    __isVMBootedSsh $TMP_MACHINE_NAME
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

function waitForOsInstall {
    local TMP_MACHINE_NAME=$1

    log "Starting waiting for guest VM to boot OS"

    while true; do
        PROBLEM="0"

        ensureSshRootConnection $TMP_MACHINE_NAME || PROBLEM=$?

        if [[ "$PROBLEM" == "0" ]]; then
            break
        fi

        sleep 10

        log "Waiting for VM \"$TMP_MACHINE_NAME\"'s OS install"
    done
}

function cloneVM {
    local ORIGINAL_NAME="$1"
    local CLONE_NAME="$2"
    local TARGET_DIR="${3:-$VIRTUAL_MACHINES_DIR}"

    log "Cloning VM $ORIGINAL_NAME -> $CLONE_NAME"

    # clear previous virtual machine if it exists
    rm -rf "$TARGET_DIR/$CLONE_NAME"

    local MAC_ADDRESS=`reserveDhcpIpForVm "$CLONE_NAME"`

    local SYSTEM_DISK_PATH="$TARGET_DIR/$CLONE_NAME/$VM_MACHINE_DISK_NAME_SYSTEM.qcow2"
    local DATA_DISK_PATH="$TARGET_DIR/$CLONE_NAME/$VM_MACHINE_DISK_NAME_DATA.qcow2"

    # ensure disk folder exists
    mkdir -p "$TARGET_DIR/$CLONE_NAME"

    virt-clone \
        --original "$ORIGINAL_NAME" \
        --name "$CLONE_NAME" \
        --mac "$MAC_ADDRESS" \
        --check disk_size=off \
        --file "$SYSTEM_DISK_PATH" \
        --file "$DATA_DISK_PATH"
}

function forkVm {
    local ORIGINAL_NAME="$1"
    local CLONE_NAME="$2"
    local TARGET_DIR="$3"

    # NOTE: due to missing group/tag feature in virt-manager, let's prefix VM name to distinguish it
    local PREFIXED_CLONE_NAME="fork_$CLONE_NAME"
    local NEW_IP=`generateIpForVm "$PREFIXED_CLONE_NAME"`

    cloneVM "$ORIGINAL_NAME" "$PREFIXED_CLONE_NAME" "$TARGET_DIR"

    tagVm "$PREFIXED_CLONE_NAME" "$VM_GROUP_FORKS"

    echo "Forking $ORIGINAL_NAME -> $PREFIXED_CLONE_NAME; IP $NEW_IP" >> "$TEST_DIR/forks.log"
}

function tagVm {
    local TMP_MACHINE_NAME="$1"
    local TAG="$2"

    # TODO: virt-manager has no group/tag feature as VirtualBox does
    #VBoxManage modifyvm "$CLONE_NAME" --groups "$VM_GROUP_FORKS"
}

function createAndPrepareVmDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"
    local DISK_SIZE="$3"
    local TARGET_FOLDER="$4"

    # config
    local MACHINE_DISK_FILE_PATH="$TARGET_FOLDER/$DISK_NAME.qcow2"

    # ensure disk folder exists
    mkdir -p "$TARGET_FOLDER"

    rm -f "$MACHINE_DISK_FILE_PATH"

    qemu-img create -f qcow2 "$MACHINE_DISK_FILE_PATH" "$DISK_SIZE" > /dev/null
    chmod g+w "$MACHINE_DISK_FILE_PATH"

    echo "$MACHINE_DISK_FILE_PATH"
}

function deleteVm {
    local TMP_MACHINE_NAME=$1

    log "Deleting VM \"$TMP_MACHINE_NAME\""

    virsh destroy "$TMP_MACHINE_NAME" 2> /dev/null || true
    virsh undefine "$TMP_MACHINE_NAME" --remove-all-storage --nvram 2> /dev/null || true

    # ensure disks and other artifacts are deleted
    rm -rf "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME"
}

function generateIpForVm() {
    local TMP_MACHINE_NAME=$1

    local HASH=$(echo -n "$TMP_MACHINE_NAME" | md5sum | sed 's/[^0-9]//g')
    local IP_SUFFIX=$(( (${HASH:0:8} % 253) + 2 ))  # range: 2-254

    echo "192.168.50.$IP_SUFFIX"
}

function reserveDhcpIpForVm {
    local TMP_MACHINE_NAME="$1"

    function generateMacForVm() {
        local TMP_MACHINE_NAME="$1"

        echo "52:54:00:$(echo -n "$TMP_MACHINE_NAME" | md5sum | sed 's/^\(..\)\(..\)\(..\).*/\1:\2:\3/')"
    }

    local MAC_ADDRESS=`generateMacForVm $TMP_MACHINE_NAME`
    local STATIC_IP=`generateIpForVm $TMP_MACHINE_NAME`

    virsh net-update $VM_NETWORK_NAME add ip-dhcp-host \
        "<host mac='$MAC_ADDRESS' ip='$STATIC_IP'/>" \
        --live --config >/dev/null 2>/dev/null || true

    echo "$MAC_ADDRESS"
}

function clearAllSanagerVms {
    log "Clearing all existing VMs"

    deleteVm "$MACHINE_NAME_TEMPORARY"
    deleteVm "$MACHINE_NAME_BARE"
    deleteVm "$MACHINE_NAME_WITH_OS"
    deleteVm "$MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS"
    deleteVm "$MACHINE_NAME_STABLE_WITH_SANAGER"

    deleteVm "$MACHINE_NAME_STABLE_TERMINAL_BASE"
    deleteVm "$MACHINE_NAME_STABLE_GRAPHICAL_BASE"
    deleteVm "$MACHINE_NAME_UNSTABLE_TERMINAL_BASE"
    deleteVm "$MACHINE_NAME_UNSTABLE_GRAPHICAL_BASE"

    deleteVm "$MACHINE_NAME_UNSTABLE_PC"
    deleteVm "$MACHINE_NAME_UNSTABLE_PHYSICAL_PC"

    deleteVm "$MACHINE_NAME_STABLE_HOME_SERVER_TERMINAL"
    deleteVm "$MACHINE_NAME_STABLE_HOME_SERVER_GRAPHICAL"
    deleteVm "$MACHINE_NAME_STABLE_CRYPTO_VISUAL"
    deleteVm "$MACHINE_NAME_STABLE_GENERAL_USE_VPS"

    rm -rf "$VIRTUAL_MACHINES_DIR"
}

function vmExists {
    local TMP_MACHINE_NAME=$1
    local PROBLEM="0"

    virsh dominfo "$TMP_MACHINE_NAME" > /dev/null 2>&1 || PROBLEM=$?

    if [[ "$PROBLEM" == "0" ]]; then
        return 0
    fi

    return 1
}


function ensureSshRootConnection {
    local TMP_MACHINE_NAME="$1"

    runTunneledSshCommand "$TMP_MACHINE_NAME" $VM_USERS_ROOT_NAME $VM_USERS_ROOT_PASSWORD exit

    # if ssh connection can't be estabilished, previous command fails;
    # thus, ssh connection is ensured at this point
}

function runTunneledSshCommand {
    local TMP_MACHINE_NAME="$1"
    local TMP_USER=$2
    local TMP_PASSWORD=$3
    local TMP_COMMAND=$4
    local TMP_ENV_ASSIGNEMENT=$5

    local SSH_HOSTNAME=`generateIpForVm "$TMP_MACHINE_NAME"`

    # ensure no conflict between VM saved and current fingerprints
    __clearSshFingerprint $SSH_HOSTNAME

    log "Running command through ssh. \`$TMP_COMMAND\`"

    sshpass \
        -p $TMP_PASSWORD \
        ssh $TMP_USER@$SSH_HOSTNAME \
            -p $GUEST_SSH_PORT \
            -o ConnectTimeout=5 \
            -o PubkeyAuthentication=no \
            -o "StrictHostKeyChecking=accept-new" \
            "$TMP_ENV_ASSIGNEMENT $TMP_COMMAND"
}

function copyTunneledSshContent {
    local TMP_MACHINE_NAME="$1"
    local TMP_USER=$2
    local TMP_PASSWORD=$3
    local TMP_LOCAL_FILEPATH=$4
    local TMP_REMOTE_FILEPATH=$5
    local TMP_EXCLUDED_PATHS=$6

    local EXCLUDED_PARAMETER=${TMP_EXCLUDED_PATHS:+"--exclude=$TMP_EXCLUDED_PATHS"}

    log "Copying files over SSH \"$TMP_LOCAL_FILEPATH\" -> \"$TMP_REMOTE_FILEPATH\" ($EXCLUDED_PARAMETER)"

    local SSH_HOSTNAME=`generateIpForVm "$TMP_MACHINE_NAME"`

    # ensure no conflict between VM saved and current fingerprints
    __clearSshFingerprint $SSH_HOSTNAME

    rsync \
        --progress \
        -avz \
        -e "sshpass \
            -p $TMP_PASSWORD \
            ssh \
                -p $GUEST_SSH_PORT \
                -o ConnectTimeout=5 \
                -o PubkeyAuthentication=no \
                -o StrictHostKeyChecking=accept-new \
        " \
        $EXCLUDED_PARAMETER \
        "$TMP_LOCAL_FILEPATH" "$TMP_USER@$SSH_HOSTNAME:$TMP_REMOTE_FILEPATH"
}

# remove any fingerprints for the host as it may come from different VM with same ssh tunnel setup
function __clearSshFingerprint {
    local SSH_HOSTNAME=$1

    log "Clearing SSH fingerprint (if exists)"

    #ssh-keygen -R [$SSH_HOSTNAME]:$GUEST_SSH_PORT # use this if port is ever used again
    ssh-keygen -R $SSH_HOSTNAME
}

# Virtualization tends to assign new id to virtual disks on VM clone (note difference "physical" virtual disk id vs filesystem UUID).
# Booting into such machine is ok, fstab and grub boot config are working. Yet futher `grub-install` will fail because
# it tries to install into no longer available disk. Changing install target to /dev/sda fixes the issue
# and is sufficient to Sanager's VM use cases.
function grubAdaptToVmCloneHardDiskIdChanges {
    local GRUB_SETTINGS_LINE="grub-pc grub-pc/install_devices multiselect /dev/vda"

    # basically running Sanager's `aptGetReinstall grub-pc`, but Sanager folder is not available yet in VM atm
    local GRUB_RECONFIGURE_COMMAND="apt-get install -y --reinstall grub-pc"

    __runTunneledCommand "echo \"$GRUB_SETTINGS_LINE\" | debconf-set-selections && $GRUB_RECONFIGURE_COMMAND"
}
