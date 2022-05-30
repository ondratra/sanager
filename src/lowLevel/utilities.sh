
function printMsg {
    echo "SANAGER: $@" >&2
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

# use:
# addGpgKey https://myrepo.example/myrepo.asc myRepoName
# addGpgKey https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF425E228 myRepoName
function addGpgKey {
    KEY_URL=$1
    KEY_NAME=$2

    TMP=`sed 's#.*\/##' <<< $KEY_URL | sed 's#\?.*$##'`
    KEY_FILE_EXTENSION=`[ $TMP == "asc" ] && echo "asc" || echo "gpg"`

    KEY_FILE_PATH="$SANAGER_GPG_KEY_DIR/$KEY_NAME.$KEY_FILE_EXTENSION"

    if [ -f $KEY_FILE_PATH ]; then
        printMsg "Skipping adding of GPG key for repo: $KEY_NAME"
        echo $KEY_FILE_PATH
        return 0
    fi

    printMsg "Adding GPG key for repo: $KEY_NAME"

    mkdir -p $SANAGER_GPG_KEY_DIR # ensure gpg keys directory
    wget --no-hsts -qO - "$KEY_URL" > $KEY_FILE_PATH

    echo $KEY_FILE_PATH
}

# use
# addAptRepository repoName "deb https://myrepo.example/someRepo stable main" https://myrepo.example/myrepo.asc
function addAptRepository {
    REPO_NAME=$1
    REPO_ROW=$2
    KEY_URL=$3

    SOURCE_LIST_PATH="/etc/apt/sources.list.d/__sanager_${REPO_NAME}.list"

    if [ -f $SOURCE_LIST_PATH ]; then
        printMsg "Skipping adding of apt repository: $REPO_NAME"
        return 0
    fi

    printMsg "Adding apt repository: $REPO_NAME"

    # add key
    KEY_FILE_PATH=`addGpgKey $KEY_URL $REPO_NAME`
    FINAL_REPO_ROW=`sed -e "s#deb#deb [signed-by=$KEY_FILE_PATH]#" <<< $REPO_ROW`
    echo "$FINAL_REPO_ROW" > $SOURCE_LIST_PATH

    aptUpdate
}

# use
# gpgKeyUrlFromKeyring keyserver.ubuntu.com F425E228
function gpgKeyUrlFromKeyring {
    KEY_SERVER=$1
    PUBKEY=$2

    echo "https://${KEY_SERVER}/pks/lookup?op=get&search=0x${PUBKEY}"
}

function wgetDownload {
    printMsg "Downloading files via wget: $@"
    wget --no-hsts $VERBOSE_WGET_FLAG "$@"
}

# use:
# applyPatch pathToFileToBePatched < patchString
function applyPatch {
    FILE_TO_BE_PATCHED=$1
    PATCH_FILE_PATH=`cat -` # read whole input from stdin

    ! PATCH_RESULT="`patch $FILE_TO_BE_PATCHED --forward <<< $PATCH_FILE_PATH`"
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
