function printMsg {
    echo "SANAGER: $@" >&2
}

function aptUpdate {
    printMsg "Updating repository cache"
    apt-get update $VERBOSE_APT_FLAG
}

function aptInstall {
    printMsg "Installing packages: $@"
    DEBIAN_FRONTEND="noninteractive" APT_LISTBUGS_FRONTEND="none" apt install "$VERBOSE_APT_FLAG" -y "$@"
}

function aptGetInstall {
    printMsg "Installing packages: $@"
    DEBIAN_FRONTEND="noninteractive" APT_LISTBUGS_FRONTEND="none" apt-get install "$VERBOSE_APT_FLAG" -y "$@"
}

function aptRemove {
    printMsg "Removing packages: $@"
    DEBIAN_FRONTEND="noninteractive" apt-get remove "$VERBOSE_APT_FLAG" -y "$@"
}

function aptDistUpgrade {
    printMsg "Upgrading distribution"
    DEBIAN_FRONTEND="noninteractive" apt-get dist-upgrade "$VERBOSE_APT_FLAG" -y
}

function aptFixDependencies {
    printMsg "Auto-removing packages"
    DEBIAN_FRONTEND="noninteractive" apt-get -f install "$VERBOSE_APT_FLAG" -y
}

function aptCleanup {
    printMsg "Fixing packages dependencies"
    DEBIAN_FRONTEND="noninteractive" apt-get autoremove "$VERBOSE_APT_FLAG" -y
}

function dpkgInstall {
    printMsg "Installing packages(dpkg/gdebi): $@"

    local VERBOSE_GDEBI_FLAG=${VERBOSE_APT_FLAG:+--quiet}

    if [ $VERBOSE_SCRIPT ]; then
        gdebi --non-interactive $VERBOSE_GDEBI_FLAG "$@"
    else
        gdebi --non-interactive $VERBOSE_GDEBI_FLAG "$@" > /dev/null
    fi
}

# usage: `dpkgDownloadAndInstall ferdium "Ferdium-linux-7.1.0-amd64.deb" "https://github.com/ferdium/ferdium-app/releases/download/v7.1.0/Ferdium-linux-7.1.0-amd64.deb"`
function dpkgDownloadAndInstall {
    APPLICATION_NAME="$1"
    DEB_FILE=$2
    PACKAGE_URL=$3

    OPT_DIR="$SANAGER_INSTALL_DIR/$APPLICATION_NAME"

    mkdir $OPT_DIR -p
    cd $OPT_DIR

    # do not install same package multiple times
    if [ -f $DEB_FILE ]; then
        return
    fi

    wgetDownload $PACKAGE_URL -O $DEB_FILE
    dpkgInstall $DEB_FILE
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

function isVirtualboxVm {
    if grep -q "VirtualBox" /sys/class/dmi/id/product_name 2>/dev/null; then
        return 1  # Running inside VirtualBox
    fi

    return 0  # Not running inside VirtualBox

    # alternative approach
    ## for detection info see http://www.dmo.ca/blog/detecting-virtualization-on-linux/
    #TMP=`dmesg | grep -i virtualbox || echo ""`
    #IS_VIRTUALBOX_GUEST=`[[ "$TMP" == "" ]] && echo 0 || echo 1`
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

    chmod go-rw ~/.gnupg/pubring.kbx # ensure this pubkey is not writable for others -> it's not clear why it's writable for them by default

    mkdir -p $SANAGER_GPG_KEY_DIR # ensure gpg keys directory
    wget --no-hsts -qO - "$KEY_URL" | sudo -u $SCRIPT_EXECUTING_USER gpg --dearmor > $KEY_FILE_PATH

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
    FINAL_REPO_ROW=`sed -e "s#deb#deb [arch=amd64 signed-by=$KEY_FILE_PATH]#" <<< $REPO_ROW`
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

# use:
# addAlias myNewAliasName existingCommand
function addAlias {
    NEW_ALIAS_NAME=$1
    EXISTING_COMMAND=$2

    ALIAS_LINE="alias $NEW_ALIAS_NAME=$EXISTING_COMMAND"

    if ! grep -q "^$ALIAS_LINE" ~/.bash_aliases; then
        sudo -u $SCRIPT_EXECUTING_USER sh -c "echo $ALIAS_LINE >> ~/.bash_aliases"
    fi
    source ~/.bash_aliases

    # TODO: it would be nice this function could make systemInstall write message **at the end of running the script**,
    #       informing user that they need to run `source ~/.bash_aliases` manually in their shell
}

# use
# addGlobalEnvVariable "my_namespace" "MY_VARIABLE=my_value"
function addGlobalEnvVariable {
    NAMESPACE=$1
    VARIABLE_DEFINITION=$2

    # ensure VARIABLE_DEFINITION really contains variable definition - prevents misuse of eval
    if ! [[ "$VARIABLE_DEFINITION" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^=]+$ ]]; then
        echo "Invalid variable definition passed to addGlobalEnvVariable!"
        exit 1
    fi

    # save variable definition
    # NOTE: env variable must be set in all 3 following configuration places
    # - /etc/environment.d/* is used by services started by systemd
    # - /etc/profile.d/* is used by "login shell"
    # - /etc/bash.bashrc is used by by both login and non-login shells
    echo "$VARIABLE_DEFINITION" > "/etc/environment.d/__sanager_$NAMESPACE.sh"
    echo "$VARIABLE_DEFINITION" > "/etc/profile.d/__sanager_$NAMESPACE.sh"
    SANAGER_GLOBAL_ENV_FILE="$SANAGER_INSTALL_DIR/bash.bashrc"
    appendToFileIfNotPresent /etc/bash.bashrc ". $SANAGER_GLOBAL_ENV_FILE"
    appendToFileIfNotPresent $SANAGER_GLOBAL_ENV_FILE "$VARIABLE_DEFINITION"

    # apply variable assignement in current shell
    eval "export $VARIABLE_DEFINITION"
}

# use
# appendToFileIfNotPresent pathToFile textToBeAppended
function appendToFileIfNotPresent {
    FILE="$1"
    TEXT="$2"

    grep -q "$TEXT" "$FILE" || echo $TEXT >> $FILE
}

function is_debian_sid {
    grep -q "sid" /etc/debian_version
}

# usage
# autostartApplication /usr/share/applications/org.corectrl.CoreCtrl.desktop
function autostartApplication {
    APPLICATION_PATH=$1

    AUTOSTART_FOLDER=~/.config/autostart/

    mkdir -p ~/.config/autostart
    cp "/usr/share/applications/$APPLICATION_PATH" $AUTOSTART_FOLDER

    # pass folder permission to relevant user
    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $AUTOSTART_FOLDER
    chmod -R +x $AUTOSTART_FOLDER
}

function isExtrepoRepositoryEnabled {
    local REPOSITORY_NAME="$1"
    local FILE="/etc/apt/sources.list.d/extrepo_${REPOSITORY_NAME}.sources"

    if [[ ! -f "$FILE" ]]; then
        return 1
    fi

    local IS_ENABLED=$(grep -i '^Enabled:' "$FILE" | awk '{print tolower($2)}')

    if [[ "$IS_ENABLED" == "no" ]]; then
        return 1
    fi

    return 0
}
