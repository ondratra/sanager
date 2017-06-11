
function printMsg {
    echo "SANAGER: $@"
}

function aptUpdate {
    printMsg "Updating repository cache"
    apt-get update $VERBOSE_APT_FLAG
}

function aptInstall {
    printMsg "Installing packages: $@"
    DEBIAN_FRONTEND="noninteractive" apt install "$VERBOSE_APT_FLAG" -y "$@"
}

function aptGetInstall {
    printMsg "Installing packages: $@"
    DEBIAN_FRONTEND="noninteractive" apt-get install "$VERBOSE_APT_FLAG" -y "$@"
}

function aptRemove {
    printMsg "Removing packages: $@"
    DEBIAN_FRONTEND="noninteractive" apt-get remove "$VERBOSE_APT_FLAG" -y "$@"
}

function dpkgInstall {
    printMsg "Installing packages(dpkg): $@"
    if [ $VERBOSE_SCRIPT ]; then
        dpkg -i "$@"
    else
        dpkg -i "$@" > /dev/null
    fi
}

function wgetDownload {
    printMsg "Downloading files via wget: $@"
    wget --no-hsts $VERBOSE_WGET_FLAG "$@"
}

# use:
# applyPatch pathToFileToBePatched < patchString
function applyPatch {
    FILE_TO_BE_PATCHED=$1
    PATCH_FILE_PATH=`cat -` # read whole input from stdinfwp

    PATCH_RESULT="`patch $FILE_TO_BE_PATCHED --forward <<< $PATCH_FILE_PATH`"
    grep -q "Reversed (or previously applied) patch detected!" <<< "$PATCH_RESULT"
    NOT_APPLIED_YET=$?

    if [[ "$NOT_APPLIED_YET" == "1" ]]; then
        printMsg "Patching file $FILE_TO_BE_PATCHED"
        return 0
    else
        printMsg "Patch already applied to $FILE_TO_BE_PATCHED"
        return 1
    fi
}
