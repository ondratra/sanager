
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

function aptDistUpgrade {
    printMsg "Upgrading distribution"
    DEBIAN_FRONTEND="noninteractive" apt-get dist-upgrade "$VERBOSE_APT_FLAG" -y
}

function dpkgInstall {
    printMsg "Installing packages(dpkg): $@"
    if [ $VERBOSE_SCRIPT ]; then
        dpkg -i "$@"
    else
        dpkg -i "$@" > /dev/null
    fi
}

# returns 0 when installed, 1 otherwise
function isInstalled {
    dpkg -s $1 > /dev/null
    NOT_INSTALLED=$?
    if [[ "$NOT_INSTALLED" == "0" ]]; then
        return 0
    fi
    return 1
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

    PATCH_RESULT="`patch $FILE_TO_BE_PATCHED --forward <<< $PATCH_FILE_PATH`" TODO!!!!!!!!!!
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

# use:
# addUserToGroup myUser myGroup
function addUserToGroup {
    USERNAME=$1
    GROUPNAME=$2

    usermod -a -G $2 $1
}
