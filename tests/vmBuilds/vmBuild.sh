
function createTestingVm {
    local TMP_MACHINE_NAME="$1"

    # config
    MACHINE_MEMORY=$((16 * 1024)) # in MB
    MACHINE_GPU_MEMORY=128 # in MB (128 is current maximum)
    MACHINE_CPU_COUNT=4

    log "Creating VM $TMP_MACHINE_NAME"

    # clear previous virtual machine if it exists
    rm -rf "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME"

    # create VM
    VBoxManage createvm \
        --name "$TMP_MACHINE_NAME" \
        --ostype "Debian_64" \
        --register \
        --basefolder $VIRTUAL_MACHINES_DIR

    # setup VM, network, and UEFI
    # enable power management
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --ioapic on \
        --firmware efi \
        --graphicscontroller vmsvga \
        ‑‑accelerate‑3d=on

    # set memory limits
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --memory $MACHINE_MEMORY \
        --vram $MACHINE_GPU_MEMORY \
        --cpus $MACHINE_CPU_COUNT

    # set network
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --nic1 nat
    # enable ssh tunnel
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --natpf1 "$VM_SSH_TUNNEL_INTERFACE_NAME,tcp,,$SSH_TUNNEL_HOST_PORT,,$SSH_TUNNEL_GUEST_PORT"

    # setup virtualization acceleration
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --pae on \
        --hwvirtex on \
        --nestedpaging on \
        --paravirtprovider kvm

    # enable (VRDE) VirtualBox Remote Desktop Extension
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --vrde on \
        --vrdemulticon on \
        --vrdeport 10001 \
        --vrdeaddress 0.0.0.0

    VBoxManage modifyvm "$TMP_MACHINE_NAME" --groups "$VM_GROUP_TESTS"
}

function createVmDisks {
    local TMP_MACHINE_NAME="$1"

    local MACHINE_DISK_SIZE=80000 # in MB
    local MACHINE_DISK_NAME="system"

    log "Creating disks for $TMP_MACHINE_NAME"

    # config
    local MACHINE_DISK_FOLDER="$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME"
    local MACHINE_DISK_FILE_PATH="$MACHINE_DISK_FOLDER/$MACHINE_DISK_NAME.vdi"

    # ensure disk folder exists
    mkdir -p $MACHINE_DISK_FOLDER

    # create IDE/NVMe controllers
    VBoxManage storagectl "$TMP_MACHINE_NAME" \
        --name "NVMe Controller" \
        --add pcie \
        --controller NVMe
    VBoxManage storagectl "$TMP_MACHINE_NAME" \
        --name "IDE Controller" \
        --add ide \
        --controller PIIX4

    # create main disk
    VBoxManage createhd \
        --filename $MACHINE_DISK_FILE_PATH \
        --size $MACHINE_DISK_SIZE \
        --format VDI

    # attack disk
    VBoxManage storageattach "$TMP_MACHINE_NAME" \
        --storagectl "NVMe Controller" \
        --port 0 \
        --device 0 \
        --type hdd \
        --medium $MACHINE_DISK_FILE_PATH

    # setup boot order
    VBoxManage modifyvm "$TMP_MACHINE_NAME" \
        --boot1 dvd \
        --boot2 disk \
        --boot3 none \
        --boot4 none
}

function attachDebianInstallationIso {
    local TMP_MACHINE_NAME=$1
    VBoxManage storageattach "$TMP_MACHINE_NAME" \
        --storagectl "IDE Controller" \
        --port 1 \
        --device 0 \
        --type dvddrive \
        --medium $NETINSTALL_FINAL_ISO_FILE
}


function attachVBoxGuestAdditions {
    local TMP_MACHINE_NAME="$1"
    VBoxManage storageattach "$TMP_MACHINE_NAME" \
        --storagectl "IDE Controller" \
        --port 1 \
        --device 0 \
        --type dvddrive \
        --medium /usr/share/virtualbox/VBoxGuestAdditions.iso
}

function deattachCd {
    local TMP_MACHINE_NAME=$1
    VBoxManage storageattach "$TMP_MACHINE_NAME" \
        --storagectl "IDE Controller" \
        --port 1 \
        --device 0 \
        --type dvddrive \
        --medium none
}

function attachVBoxGuestAdditions {
    # attach guest addition medium
    VBoxManage storageattach "$TMP_MACHINE_NAME" \
        --storagectl "IDE Controller" \
        --port 1 \
        --device 0 \
        --type dvddrive \
        --medium /usr/share/virtualbox/VBoxGuestAdditions.iso
}

function buildOnTopOfVm {
    local ORIGINAL_VM_NAME="$1"
    local NEW_VM_NAME="$2"
    local FUNCTION_TO_APPLY="$3"

    log "Building on top of VM - \"$ORIGINAL_VM_NAME\" -> \"$NEW_VM_NAME\""

    # create working VM
    cloneVM "$ORIGINAL_VM_NAME" "$MACHINE_NAME_TEMPORARY"

    # call routine that's to be applied to VM
    $FUNCTION_TO_APPLY "$MACHINE_NAME_TEMPORARY"

    # escape if applied function failed
    local FUNCTION_EXIT_CODE=$?
    if [ $FUNCTION_EXIT_CODE -ne 0 ]; then
        log "VM build failed. \""$ORIGINAL_VM_NAME"\" -> \"$NEW_VM_NAME\" using \`$FUNCTION_TO_APPLY\`"
        deleteVm "$MACHINE_NAME_TEMPORARY"
        return
    fi

    # save result VM
    cloneVM "$MACHINE_NAME_TEMPORARY" $NEW_VM_NAME

    # delete temporary VM
    deleteVm "$MACHINE_NAME_TEMPORARY"

    log "Building of \"$NEW_VM_NAME\" done successfully"
}

function cachedBuildOnTopOfVm {
    local ORIGINAL_VM_NAME="$1"
    local NEW_VM_NAME="$2"
    local FUNCTION_TO_APPLY="$3"

    if [[ `vmExists $NEW_VM_NAME` == "0" ]]; then
        return
    fi

    buildOnTopOfVm "$ORIGINAL_VM_NAME" "$NEW_VM_NAME" "$FUNCTION_TO_APPLY"
}
