function getDiskFilePath {
    local IS_FORK_PATH="$1"
    local TMP_MACHINE_NAME="$2"
    local DISK_NAME="$3"

    local FOLDER_PATH=`getDiskFolderPath "$IS_FORK_PATH" "$TMP_MACHINE_NAME"`

    echo "$FOLDER_PATH/$DISK_NAME.qcow2"
}

function getDiskFolderPath {
    local IS_FORK_PATH=$1
    local TMP_MACHINE_NAME="$2"

    echo "$VIRTUAL_MACHINES_DIR/$TMP_MACHINE_NAME"
}

function createDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"
    local DISK_SIZE="$3"

    # config
    local MACHINE_DISK_FILE_PATH=`getDiskFilePath "" "$TMP_MACHINE_NAME" "$DISK_NAME"`
    local TARGET_FOLDER=`getDiskFolderPath "" "$TMP_MACHINE_NAME"`

    # ensure disk folder exists
    mkdir -p "$TARGET_FOLDER"

    # clear existing disk if any
    rm -f "$MACHINE_DISK_FILE_PATH"

    local MACHINE_DISK_FILE_PATH

    qemu-img create -f qcow2 "$MACHINE_DISK_FILE_PATH" "$DISK_SIZE" > /dev/null
    chmod g+w "$MACHINE_DISK_FILE_PATH"

    echo "$MACHINE_DISK_FILE_PATH"
}

function deleteDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"

    local MACHINE_DISK_FILE_PATH=`getDiskFilePath "" "$TMP_MACHINE_NAME" "$DISK_NAME"`

    rm -f "$MACHINE_DISK_FILE_PATH"
}

function deleteDiskNamespace {
    local TMP_MACHINE_NAME="$1"

    local FOLDER_PATH=`getDiskFolderPath "" "$TMP_MACHINE_NAME"`

    rm -rf "$FOLDER_PATH"
}

function cloneDisk {
    local IS_CREATING_FORK="$1"
    local ORIGINAL_MACHINE_NAME="$2"
    local CLONE_MACHINE_NAME="$3"
    local DISK_NAME="$4"

    local ORIGINAL_FOLDER=`getDiskFolderPath "$IS_CREATING_FORK" "$ORIGINAL_MACHINE_NAME"`
    local TARGET_FOLDER=`getDiskFolderPath "$IS_CREATING_FORK" "$CLONE_MACHINE_NAME"`

    local EXISTING_MACHINE_DISK_FILE_PATH="$ORIGINAL_FOLDER/$DISK_NAME.qcow2"
    local NEW_MACHINE_DISK_FILE_PATH="$TARGET_FOLDER/$DISK_NAME.qcow2"

    # ensure disk folder exists
    mkdir -p "$TARGET_FOLDER"

    # clear existing disk if any
    rm -f "$NEW_MACHINE_DISK_FILE_PATH"

    cp "$EXISTING_MACHINE_DISK_FILE_PATH" "$NEW_MACHINE_DISK_FILE_PATH"

    echo "$NEW_MACHINE_DISK_FILE_PATH"
}
