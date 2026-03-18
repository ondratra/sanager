function getDiskFolder {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"

    echo "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME/$DISK_NAME.qcow2"
}

function createDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"
    local DISK_SIZE="$3"

    # config
    local MACHINE_DISK_FILE_PATH=`getDiskFolder "$TMP_MACHINE_NAME" "$DISK_NAME"`

    # ensure disk folder exists
    mkdir -p "$TARGET_FOLDER"

    rm -f "$MACHINE_DISK_FILE_PATH"

    local MACHINE_DISK_FILE_PATH

    qemu-img create -f qcow2 "$MACHINE_DISK_FILE_PATH" "$DISK_SIZE" > /dev/null
    chmod g+w "$MACHINE_DISK_FILE_PATH"

    echo "$MACHINE_DISK_FILE_PATH"
}

function deleteDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"

    local MACHINE_DISK_FILE_PATH=`getDiskFolder "$TMP_MACHINE_NAME" "$DISK_NAME"`

    rm -f "$MACHINE_DISK_FILE_PATH"
}

function deleteDiskNamespace {
    local TMP_MACHINE_NAME="$1"

    local MACHINE_DISK_NAMESPACE_FILE_PATH=`getDiskFolder "$TMP_MACHINE_NAME" ""`

    rm -rf "$MACHINE_DISK_NAMESPACE_FILE_PATH"
}

function cloneDisk {
    local ORIGINAL_MACHINE_NAME="$1"
    local CLONE_MACHINE_NAME="$2"
    local DISK_NAME="$3"

    local EXISTING_MACHINE_DISK_FILE_PATH="$ORIGINAL_FOLDER/$DISK_NAME.qcow2"
    local NEW_MACHINE_DISK_FILE_PATH="$TARGET_FOLDER/$DISK_NAME.qcow2"

    cp "$EXISTING_MACHINE_DISK_FILE_PATH" "$NEW_MACHINE_DISK_FILE_PATH"
}
