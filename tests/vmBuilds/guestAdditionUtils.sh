function vmShareFolder {
    local TMP_MACHINE_NAME="$1"
    local HOST_FOLDER_PATH="$2"
    #local GUEST_USER_NAME="$3"
    local GUEST_FOLDER_NAME=$3
    local GUEST_FOLDER_PATH="$4"

    log "Sharing folder \"$HOST_FOLDER_PATH\" -> \"$TMP_MACHINE_NAME:$GUEST_FOLDER_PATH\" as \"$GUEST_FOLDER_NAME\""

    # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-sharedfolder.html
    VBoxManage sharedfolder add $TMP_MACHINE_NAME \
        --name "$GUEST_FOLDER_NAME" \
        --hostpath "$HOST_FOLDER_PATH" \
        --readonly \
        --automount \
        --auto-mount-point "$GUEST_FOLDER_PATH"

    # this is likely not needed with properly working guest additions
    # In guest - later on somewhere in this code call
    # sudo usermod -a -G vboxsf $GUEST_USER_NAME
}

# use:
# vmExecShellCommand myVmName myBashCommand env1=myValue1 env2=myValue2 ...
# e.g. vmExecShellCommand MyVM1 "/bin/bash ./myScript.sh" MY_ENV_VARIABLE=123
function vmExecShellCommand {
    local TMP_MACHINE_NAME=$1
    local COMMAND=$2
    local ENV_ASSIGNMENTS=${@:3}

    local ENV_PARAMETERS=""

    for ASSIGNMENT in "$ENV_ASSIGNMENTS"; do
        ENV_PARAMETERS="$ENV_PARAMETERS $ASSIGNMENT \\"
    done

    VBoxManage guestcontrol $TMP_MACHINE_NAME run \
        --verbose \
        --username $VM_USERS_ROOT_NAME \
        --password $VM_USERS_ROOT_PASSWORD \
        --verbose \
        $ENV_PARAMETERS
        --exe $COMMAND
}