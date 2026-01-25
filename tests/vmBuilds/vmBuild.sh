function createTestingVm {
    local TMP_MACHINE_NAME="$1"

    # config
    local MACHINE_MEMORY=$((16 * 1024)) # MB
    local MACHINE_CPU_COUNT=4

    log "Creating VM $TMP_MACHINE_NAME"

    # remove existing VM if present
    virsh destroy "$TMP_MACHINE_NAME" 2>/dev/null || true
    virsh undefine "$TMP_MACHINE_NAME" --nvram 2>/dev/null || true

    local MAC_ADDRESS=`reserveDhcpIpForVm "$TMP_MACHINE_NAME"`

    virt-install \
        --name "$TMP_MACHINE_NAME" \
        --os-variant debianunstable \
        --memory "$MACHINE_MEMORY" \
        --vcpus "$MACHINE_CPU_COUNT" \
        --cpu host \
        --machine q35 \
        --boot uefi \
        --graphics spice,gl.enable=yes,gl.rendernode=/dev/dri/renderD128,listen=none \
        --video virtio,accel3d=yes \
        --network network=$VM_NETWORK_NAME,model=virtio \
        --mac "$MAC_ADDRESS" \
        --disk none \
        --noautoconsole \
        --print-xml > "$TMP_VM_DEFINITION_PATH"

    virsh define "$TMP_VM_DEFINITION_PATH"
}

function createVmDisks {
    local TMP_MACHINE_NAME="$1"

    log "Creating disks for $TMP_MACHINE_NAME"

    local SYSTEM_DISK_PATH=`createAndPrepareVmDisk "$TMP_MACHINE_NAME" "$VM_MACHINE_DISK_NAME_SYSTEM" "$VM_MACHINE_DISK_SIZE_SYSTEM" "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME"`
    local DATA_DISK_PATH=`createAndPrepareVmDisk "$TMP_MACHINE_NAME" "$VM_MACHINE_DISK_NAME_DATA" "$VM_MACHINE_DISK_SIZE_DATA" "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME"`

    virsh attach-disk "$TMP_MACHINE_NAME" \
        "$SYSTEM_DISK_PATH" vda \
        --driver qemu \
        --subdriver qcow2 \
        --targetbus virtio \
        --persistent
    virsh attach-disk "$TMP_MACHINE_NAME" \
        "$DATA_DISK_PATH" vdb \
        --driver qemu \
        --subdriver qcow2 \
        --targetbus virtio \
        --persistent
}

function attachDebianInstallationIso {
    local TMP_MACHINE_NAME=$1

    virsh attach-disk "$TMP_MACHINE_NAME" \
        "$NETINSTALL_FINAL_ISO_FILE" \
        hda \
        --type cdrom \
        --mode readonly \
        --targetbus sata \
        --config
}

function deattachCd {
    local TMP_MACHINE_NAME=$1

    virsh change-media "$TMP_MACHINE_NAME" hda --eject --config
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

    if vmExists $NEW_VM_NAME; then
        return
    fi

    buildOnTopOfVm "$ORIGINAL_VM_NAME" "$NEW_VM_NAME" "$FUNCTION_TO_APPLY"
}
