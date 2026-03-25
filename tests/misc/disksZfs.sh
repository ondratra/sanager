function getZfsDatasetPath {
    local IS_FORK_PATH=$1
    local TMP_MACHINE_NAME="$2"
    local DISK_NAME="$3"
    local ZVOL_ARCHETYPE="$4"

    local DATASET_NAME_SUFFIX="$TMP_MACHINE_NAME/$DISK_NAME"

    if [[ -z "$ZVOL_ARCHETYPE" ]]; then
        # NOTE: this expects that there are no two dataset with same machine name and disk name
        zfs list -H -o name | grep "$DATASET_NAME_SUFFIX\$"
        return 0
    fi

    local FALLBACK_PARENT_PATH="VM_ZPOOL_DATASET_${IS_FORK_PATH:+"FORKS_"}PARENT"

    local MB_DATASET_PARENT_FOR_ARCHETYPE="${FALLBACK_PARENT_PATH}_FOR_${ZVOL_ARCHETYPE}"
    local DATASET_PARENT="${!MB_DATASET_PARENT_FOR_ARCHETYPE:-${!FALLBACK_PARENT_PATH:-$VM_ZPOOL_DATASET_PARENT}}"

    echo "$DATASET_PARENT/$DATASET_NAME_SUFFIX"
}

function getZvolDevPath {
    local DATASET_NAME="$1"

    echo "/dev/zvol/$DATASET_NAME"
}

function createDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"
    local DISK_SIZE="$3"
    local ZVOL_ARCHETYPE="$4"

    # dataset settings
    local VOLBLOCKSIZE="ZFS_ZVOL_ARCH_${ZVOL_ARCHETYPE}_VOLBLOCKSIZE"
    local SYNC="ZFS_ZVOL_ARCH_${ZVOL_ARCHETYPE}_SYNC"
    local COMPRESSION="ZFS_ZVOL_ARCH_${ZVOL_ARCHETYPE}_COMPRESSION"
    local PRIMARYCACHE="ZFS_ZVOL_ARCH_${ZVOL_ARCHETYPE}_PRIMARYCACHE"
    local LOGBIAS="ZFS_ZVOL_ARCH_${ZVOL_ARCHETYPE}_LOGBIAS"

    if [ -z "${!VOLBLOCKSIZE}" ]; then
        echo "Unknown VM archetype for ZFS disk creation: '$ZVOL_ARCHETYPE'"
        exit 1
    fi

    local DATASET_NAME=`getZfsDatasetPath "" "$TMP_MACHINE_NAME" "$DISK_NAME" "$ZVOL_ARCHETYPE"`

    # destroy already existing dataset (if exist)
    deleteDisk "$TMP_MACHINE_NAME" "$DISK_NAME"

    # -s enables creation of bigger datasets/zvols than available physical space
    zfs create \
        -p \
        -s \
        -V $DISK_SIZE \
        -b "${!VOLBLOCKSIZE}" \
        -o "sync=${!SYNC}" \
        -o "compression=${!COMPRESSION}" \
        -o "primarycache=${!PRIMARYCACHE}" \
        -o "logbias=${!LOGBIAS}" \
        "$DATASET_NAME"

    getZvolDevPath "$DATASET_NAME"
}

function deleteDisk {
    local TMP_MACHINE_NAME="$1"
    local DISK_NAME="$2"

    local DATASET_NAME=`getZfsDatasetPath "" "$TMP_MACHINE_NAME" "$DISK_NAME"`

    if [[ -z "$DATASET_NAME" ]]; then
        return
    fi

    zfs destroy -r "$DATASET_NAME" > /dev/null 2> /dev/null || true
}

function deleteDiskNamespace {
    local TMP_MACHINE_NAME="$1"

    for ZVOL_ARCHETYPE in $ZFS_ZVOL_ARCHITECTURES; do
        local MB_DATASET_PARENT_FOR_ARCHETYPE="VM_ZPOOL_DATASET_PARENT_FOR_${ZVOL_ARCHETYPE}"
        local DATASET_PARENT="${!MB_DATASET_PARENT_FOR_ARCHETYPE}"

        if [[ -n "$DATASET_PARENT" ]]; then
            zfs destroy -r "$DATASET_PARENT/$TMP_MACHINE_NAME" > /dev/null 2> /dev/null || true
        fi
    done
}

function cloneDisk {
    local IS_CREATING_FORK="$1"
    local ORIGINAL_MACHINE_NAME="$2"
    local CLONE_MACHINE_NAME="$3"
    local DISK_NAME="$4"
    local ZVOL_ARCHETYPE="${5:-$ZFS_ZVOL_ARCH_GENERIC}"

    local ORIGINAL_DATASET_NAME=`getZfsDatasetPath "" "$ORIGINAL_MACHINE_NAME" "$DISK_NAME" "$ZVOL_ARCHETYPE"`
    local NEW_DATASET_NAME=`getZfsDatasetPath "$IS_CREATING_FORK" "$CLONE_MACHINE_NAME" "$DISK_NAME" "$ZVOL_ARCHETYPE"`
    local NEW_DATASET_PARENT_PATH="${NEW_DATASET_NAME%/*}"

    local SNAPSHOT_NAME="$ORIGINAL_DATASET_NAME@sanagercloning"

    local DISK_SIZE=`getDiskSize "$ORIGINAL_DATASET_NAME"`
    #local ZVOL_PATH=`createDisk "$CLONE_MACHINE_NAME" "$DISK_NAME" "$DISK_SIZE" "$ZVOL_ARCHETYPE"`

    # ensure parent path exist
    zfs create -p -o mountpoint=none "$NEW_DATASET_PARENT_PATH"
    # destroy already existing dataset (if exist)
    deleteDisk "$CLONE_MACHINE_NAME" "$DISK_NAME"

    # destroy existing snapshot (if exists)
    zfs destroy "$SNAPSHOT_NAME" > /dev/null 2> /dev/null || true
    # create snapshot for clone
    zfs snapshot "$SNAPSHOT_NAME"

    # NOTE: zfs cloning doesn't let us delete temporary snapshosts, rather use zfs send & recieve for now
    #       it's slower because it copies data, but likely will create less maintanance problems
    # zfs clone "$SNAPSHOT_NAME" "$NEW_DATASET_NAME"

    zfs send "$SNAPSHOT_NAME" | zfs receive "$NEW_DATASET_NAME"
    zfs destroy "$SNAPSHOT_NAME"

    # TODO: adjust zvol settings according to selected ZVOL_ARCHETYPE

    getZvolDevPath "$NEW_DATASET_NAME"
}

function getDiskSize {
    local DATASET_NAME="$1"

    zfs get volsize "$DATASET_NAME" -o value -H
}
