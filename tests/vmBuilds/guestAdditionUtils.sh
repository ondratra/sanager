function vmShareFolder {
    local TMP_MACHINE_NAME="$1"
    local HOST_FOLDER_PATH="$2"
    local GUEST_FOLDER_NAME="$3"
    local GUEST_FOLDER_PATH="$4"

    log "Sharing folder \"$HOST_FOLDER_PATH\" -> \"$TMP_MACHINE_NAME:$GUEST_FOLDER_PATH\" as \"$GUEST_FOLDER_NAME\""

    # add shared folder to the VM configuration
    virt-xml "$TMP_MACHINE_NAME" --add-device \
      --filesystem type=mount,accessmode=passthrough,source.dir="$HOST_FOLDER_PATH",target.dir="$GUEST_FOLDER_NAME",readonly=on

    # setup automount inside the guest
    # NOTE: virt-customize can't be run like this due to permission issue in our stack - virtual disk files are owned
    #       by root:root, while virt-customize (via this script) runs as regular user
    #virt-customize -d "$TMP_MACHINE_NAME" \
    #  --mkdir "$GUEST_FOLDER_PATH" \
    #  --append-line "/etc/fstab:$GUEST_FOLDER_NAME $GUEST_FOLDER_PATH 9p trans=virtio,version=9p2000.L,ro,nofail 0 0"
    local FSTAB_MOUNT_LINE="$GUEST_FOLDER_NAME $GUEST_FOLDER_PATH 9p trans=virtio,version=9p2000.L,ro,nofail 0 0"
    __bootstrapVm "$TMP_MACHINE_NAME"
    __runTunneledCommand "mkdir -p '$GUEST_FOLDER_PATH' && echo '$FSTAB_MOUNT_LINE' | tee -a /etc/fstab"
    stopVm "$TMP_MACHINE_NAME"
}
