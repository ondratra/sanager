
function log {
    echo "SANAGER TESTS: $@"
}

function requireTestConfigInit {
    if [ ! -f "$TEST_DIR/customConfig.sh" ]; then
        log Sanager tests not initialized. Use \`scripts/initTests.sh\`
        exit 1
    fi
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

    while [ "$(LANG=C virsh domstate --domain "$TMP_MACHINE_NAME")" != "shut off" ]; do
        log Waiting for VM to shutdown - $TMP_MACHINE_NAME
        sleep 3
    done
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
    local VM_TYPE="${4:-$ZFS_ZVOL_ARCH_GENERIC}"

    log "Cloning VM $ORIGINAL_NAME -> $CLONE_NAME"

    # clear previous virtual machine if it exists
    rm -rf "$TARGET_DIR/$CLONE_NAME"

    local MAC_ADDRESS=`reserveDhcpIpForVm "$CLONE_NAME" "$VM_NETWORK_NAME" "$VM_NETWORK_PREFIX"`

    local SYSTEM_DISK_PATH=`cloneDisk "$ORIGINAL_NAME" "$CLONE_NAME" "$VM_MACHINE_DISK_NAME_SYSTEM" "$ZFS_ZVOL_ARCH_OS"`
    local DATA_DISK_PATH=`cloneDisk "$ORIGINAL_NAME" "$CLONE_NAME" "$VM_MACHINE_DISK_NAME_DATA" "$VM_TYPE"`

    # ensure disk folder exists
    mkdir -p "$TARGET_DIR/$CLONE_NAME"

    virt-clone \
        --original "$ORIGINAL_NAME" \
        --name "$CLONE_NAME" \
        --mac "$MAC_ADDRESS" \
        --check disk_size=off \
        --preserve-data \
        --file "$SYSTEM_DISK_PATH" \
        --file "$DATA_DISK_PATH"
}

function forkVm {
    local ORIGINAL_NAME="$1"
    local CLONE_NAME="$2"
    local TARGET_DIR_OR_ZFS_ZVOL="$3"

    # NOTE: due to missing group/tag feature in virt-manager, let's prefix VM name to distinguish it
    local PREFIXED_CLONE_NAME="fork_$CLONE_NAME"
    local NEW_IP=`generateIpForVm "$PREFIXED_CLONE_NAME" "$VM_NETWORK_PREFIX"`

    cloneVM "$ORIGINAL_NAME" "$PREFIXED_CLONE_NAME" "$TARGET_DIR_OR_ZFS_ZVOL"

    tagVm "$PREFIXED_CLONE_NAME" "$VM_GROUP_FORKS"

    echo "Forking $ORIGINAL_NAME -> $PREFIXED_CLONE_NAME; IP $NEW_IP" >> "$TEST_DIR/forks.log"
}

function connectVMs {
    local NETWORK_INDEX="$1"

    echo $NETWORK_INDEX ${@:2} $@
    local NETWORK_NAME="$VM_CONNECTING_NETWORK_NAME-$NETWORK_INDEX"

    ensureVMNetworksExist "$VM_CONNECTING_NETWORK_NAME" "$NETWORK_INDEX"

    for VM_NAME in "${@:2}"; do
        echo "Attaching $VM_NAME to $NETWORK_NAME"

        virsh attach-interface --domain "$VM_NAME" \
          --type network \
          --source "$NETWORK_NAME" \
          --model virtio \
          --config
    done
}

function tagVm {
    local TMP_MACHINE_NAME="$1"
    local TAG="$2"

    # TODO: virt-manager has no group/tag feature as VirtualBox does
    #VBoxManage modifyvm "$CLONE_NAME" --groups "$VM_GROUP_FORKS"
}

function deleteVm {
    local TMP_MACHINE_NAME=$1

    log "Deleting VM \"$TMP_MACHINE_NAME\""

    virsh destroy "$TMP_MACHINE_NAME" 2> /dev/null || true
    virsh undefine "$TMP_MACHINE_NAME" --remove-all-storage --nvram 2> /dev/null || true

    deleteDisk "$TMP_MACHINE_NAME" "$VM_MACHINE_DISK_NAME_SYSTEM"
    deleteDisk "$TMP_MACHINE_NAME" "$VM_MACHINE_DISK_NAME_DATA"

    deleteDiskNamespace "$TMP_MACHINE_NAME"
}

function generateIpForVm() {
    local TMP_MACHINE_NAME="$1"
    local NETWORK_PREFIX="$2"

    local HASH=$(echo -n "$TMP_MACHINE_NAME" | md5sum | sed 's/[^0-9]//g')
    local IP_THIRD=$(( (${HASH:0:4} % 256) )) # range: 0-255
    local IP_FOURTH=$(( (${HASH:4:8} % 253) + 2 )) # range: 2-254

    echo "$NETWORK_PREFIX.$IP_THIRD.$IP_FOURTH"
}

function reserveDhcpIpForVm {
    local TMP_MACHINE_NAME="$1"
    local NETWORK_NAME="$2"
    local NETWORK_PREFIX="$3"

    function generateMacForVm() {
        local TMP_MACHINE_NAME="$1"

        echo "52:54:00:$(echo -n "$TMP_MACHINE_NAME" | md5sum | sed 's/^\(..\)\(..\)\(..\).*/\1:\2:\3/')"
    }

    local MAC_ADDRESS=`generateMacForVm "$TMP_MACHINE_NAME-$NETWORK_PREFIX"`
    local STATIC_IP=`generateIpForVm "$TMP_MACHINE_NAME" "$NETWORK_PREFIX"`

    # delete existing static lease (if any)
    virsh net-update "$NETWORK_NAME" delete ip-dhcp-host \
        "<host mac='$MAC_ADDRESS'/>" \
        --live --config >/dev/null 2>/dev/null || true
    # create new static lease
    virsh net-update "$NETWORK_NAME" add ip-dhcp-host \
        "<host mac='$MAC_ADDRESS' ip='$STATIC_IP' name='$TMP_MACHINE_NAME'/>" \
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
    deleteVm "$MACHINE_NAME_STABLE_HOME_SERVER_TERMINAL"
    deleteVm "$MACHINE_NAME_STABLE_HOME_SERVER_GRAPHICAL"
    deleteVm "$MACHINE_NAME_STABLE_CRYPTO_VISUAL"
    deleteVm "$MACHINE_NAME_STABLE_GENERAL_USE_VPS"

    deleteVm "$MACHINE_NAME_UNSTABLE_BASE"
    deleteVm "$MACHINE_NAME_UNSTABLE_TERMINAL_BASE"
    deleteVm "$MACHINE_NAME_UNSTABLE_GRAPHICAL_BASE"
    deleteVm "$MACHINE_NAME_UNSTABLE_AI_CORE"
    deleteVm "$MACHINE_NAME_UNSTABLE_PC"
    deleteVm "$MACHINE_NAME_UNSTABLE_PHYSICAL_PC"

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

    local SSH_HOSTNAME=`generateIpForVm "$TMP_MACHINE_NAME" "$VM_NETWORK_PREFIX"`

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

    local SSH_HOSTNAME=`generateIpForVm "$TMP_MACHINE_NAME" "$VM_NETWORK_PREFIX"`

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

# expects user `libvirt-qemu` is running libvirt and testing folder is not owned by it or any of it's groups
function detectMissingAccessToTestingFolder {
    local PATH_TO_FOLDER="$1"

    local NORMALIZED_PATH="$(readlink -f -- "$PATH_TO_FOLDER")"
    local CURRENT_PATH="$NORMALIZED_PATH"

    while [[ "$CURRENT_PATH" != "/" ]]; do
        local MODE=$(stat -Lc '%a' "$CURRENT_PATH")
        local PERMISSIONS_FOR_OTHERS=${MODE:-1}

        if ! (( $PERMISSIONS_FOR_OTHERS & 1 )); then
            printMsg "Missing execute (x) file permission on directory: $CURRENT_PATH"
            return 1
        fi

        CURRENT_PATH="$(dirname "$CURRENT_PATH")"
    done
}

function isZfsEnabled {
    [[ -n "$VM_ZPOOL_DATASET_PARENT" ]]
}


function isPathZpoolDatasetPath {
    local MB_ZPOOL_PATH="$1"

    if which zfs > /dev/null 2> /dev/null && zfs list "$MB_ZPOOL_PATH" > /dev/null 2> /dev/null; then
        return 0
    fi

    return 1
}
