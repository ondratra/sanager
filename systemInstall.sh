#!/bin/bash
# see README.md for script description

###############################################################################
# Permission lock - only regular user using `sude -E` is allowed
###############################################################################

if [[ "$SUDO_USER" == "" ]]; then
    TMP='`sudo -E '$0'`'
    echo "You should run this script as regular user. Run: $TMP"
    echo "It's the only way to use your ssh keys for git auth, etc."
    exit 1;
fi


###############################################################################
# Settings and helpers
###############################################################################

# used when importing ubuntu packages
NOWADAYS_UBUNTU_VERSION="xenial"
SANAGER_INSTALL_DIR="/opt/sanagerInstall"

SCRIPT_EXECUTING_USER=$SUDO_USER
SCRIPT_DIR="`dirname \"$0\"`" # relative
SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized

VERBOSE_SCRIPT=`[[ "$1" == "--verbose" ]] && echo 1 || echo 0`
VERBOSE_APT_FLAG=`[[ "$VERBOSE_SCRIPT" == "1" ]] && echo "" || echo "-qq"`
VERBOSE_WGET_FLAG=`[[ "$VERBOSE_SCRIPT" == "0" ]] && echo "" || echo "-q"`

# for detection info see http://www.dmo.ca/blog/detecting-virtualization-on-linux/
TMP=`dmesg | grep -i virtualbox`
IS_VIRTUALBOX_GUEST=`[[ "$TMP" == "" ]] && echo 0 || echo 1`

function printMsg {
    echo "SANAGER: $@"
}

function aptUpdate {
    printMsg "Updating repository cache"
    apt-get update $VERBOSE_APT_FLAG
}

function aptInstall {
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


###############################################################################
# Definitions of functions installing system components
###############################################################################

function essential {
    PACKAGES="apt-transport-https aptitude wget net-tools bash-completion"

    aptInstall $PACKAGES
}

function desktopDisplayEtc {
    PACKAGES="pulseaudio dconf-cli"
    XORG="xorg"
    DESKTOP="mate mate-desktop-environment mate-desktop-environment-extras"
    DISPLAY="lightdm"

    function ininalityFonts {
        PACKAGES="fontconfig-infinality"
        REPO_ROW="deb http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu $NOWADAYS_UBUNTU_VERSION main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/ininality-fonts.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E985B27B # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
            aptInstall $PACKAGES
        fi
    }

    function networkManager {
        PACKAGES="network-manager network-manager-gnome"

        # see https://wiki.debian.org/NetworkManager#Wired_Networks_are_Unmanaged
        applyPatch /etc/NetworkManager/NetworkManager.conf < $SCRIPT_DIR/data/misc/NetworkManager.conf.diff
        PATCH_PROBLEM=$?

        if [[ "$PATCH_PROBLEM" == "0" ]]; then
            systemctl restart network-manager
        fi
        aptInstall $PACKAGES
    }

    aptInstall $XORG # run this first separately to prevent D-bus init problems
    aptInstall $PACKAGES $DESKTOP $DISPLAY
    ininalityFonts
    networkManager
}

function virtualboxGuest {
    if [[ "$IS_VIRTUALBOX_GUEST" == "0" ]]; then
        return
    fi

    aptInstall virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms
}

function userEssential {
    PACKAGES="curl vim htop firefox chromium disk-manager"

    # enables bash histroy search by PageUp and PageDown keys
    function enableHistorySearch {
        # works system wide (changing /etc/inputrc)
        sed -e '/.*\(history-search-backward\|history-search-forward\)/s/^# //g' /etc/inputrc > tmpSadReplacementFile && mv tmpSadReplacementFile /etc/inputrc
    }

    function enableBashCompletion {
        applyPatch /etc/bash.bashrc < $SCRIPT_DIR/data/misc/bash.bashrc.diff
    }


    function dropbox {
        PACKAGES="lsb-release"
        OPT_DIR="$SANAGER_INSTALL_DIR/dropbox"
        DEB_FILE="dropbox_2015.10.28_amd64.deb"

        mkdir $OPT_DIR -p
        cd $OPT_DIR

        if [ ! -f $DEB_FILE ]; then
            aptInstall lsb-release
            wgetDownload "https://www.dropbox.com/download?dl=packages/debian/$DEB_FILE" -O $DEB_FILE
            dpkgInstall $DEB_FILE
            dropbox start -i
        fi
    }

    function restoreMateConfig {
        # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
        sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS dconf load /org/mate/ < "$SCRIPT_DIR/data/mate/config.txt"
    }

    aptInstall $PACKAGES
    enableHistorySearch
    enableBashCompletion
    restoreMateConfig
    dropbox
}

function work {
    PACKAGES="git subversion meld virtualbox gimp youtube-dl"
    OFFICE="thunderbird libreoffice"

    function sublimeText {
        OPT_DIR="$SANAGER_INSTALL_DIR/sublimeText"
        DEB_FILE="sublime-text_build-3126_amd64.deb"
        PACKAGE_CONTROL_DOWNLOAD_URL="https://packagecontrol.io/Package%20Control.sublime-package"
        CONFIG_DIR=~/.config/sublime-text-3

        function ensureSublimeInstall {
            # download and install package if absent
            if [ ! -f $DEB_FILE ]; then
                wgetDownload "https://download.sublimetext.com/$DEB_FILE"
                dpkgInstall $DEB_FILE
            fi
        }

        function refreshSublimeConfiguration {
            INSTALLED_PACKAGES_DIR="$CONFIG_DIR/Installed Packages"
            PACKAGE_LOCAL_NAME="Ondratra"
            FILES_TO_SYMLINK=("Preferences.sublime-settings" "Default (Linux).sublime-keymap" "SideBarEnhancements")

            # download editor's configuration and setup everything
            sudo -u $SCRIPT_EXECUTING_USER mkdir $CONFIG_DIR -p
            mkdir "$INSTALLED_PACKAGES_DIR" -p
            mkdir "$CONFIG_DIR/Packages/User" -p
            cp "$SCRIPT_DIR/data/sublimeText" "$CONFIG_DIR/Packages/$PACKAGE_LOCAL_NAME" -rT
            for TMP_FILE in "${FILES_TO_SYMLINK[@]}"; do
                ln -sf "../$PACKAGE_LOCAL_NAME/$TMP_FILE" "$CONFIG_DIR/Packages/User/$TMP_FILE"
            done

            # download package control when absent
            if [ ! -f "$INSTALLED_PACKAGES_DIR/Package Control.sublime-package" ]; then
                # download package control for sublime text -> it will download all other packages on first run
                wgetDownload --directory-prefix "$INSTALLED_PACKAGES_DIR" $PACKAGE_CONTROL_DOWNLOAD_URL
            fi

            # pass folder permission to relevant user
            chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_DIR
        }

        mkdir $OPT_DIR -p
        cd $OPT_DIR
        ensureSublimeInstall
        refreshSublimeConfiguration
    }

    # newest version of nodejs (not among Debian packages yet)
    function nodejs {
        PACKAGES="nodejs"
        REPO_ROW="deb https://deb.nodesource.com/node_7.x jessie main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/nodejs.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            wgetDownload -qO - "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" | apt-key add -
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
        fi

        # there exists some 'yarn' command in 'cmdtest' package - not used so get rid of it
        aptRemove cmdtest
        aptInstall $PACKAGES
    }

    function yarnpkg {
        PACKAGES="yarn"
        REPO_ROW="deb https://dl.yarnpkg.com/debian/ stable main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/yarn.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            wgetDownload -qO - "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add -
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
        fi

        aptInstall $PACKAGES
    }

    # Linux Apache MySQL PHP
    function lamp {
        # subversion(svn) is needed by some composer(https://getcomposer.org/) packages, etc.
        # it must be installed even when not directly used by system users
        PACKAGES="mysql-server apache2 php libapache2-mod-php subversion"
        PHP_EXTENSIONS="php-curl php-gd php-mysql php-json php-soap php-apcu php-xml php-mbstring php-yaml"

        function wordpressCli {
            which wp-cli > /dev/null
            CLI_ABSENT=$?

            if [[ "$CLI_ABSENT" == "1" ]]; then
                PHAR_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
                wgetDownload --directory-prefix $SANAGER_INSTALL_DIR $PHAR_URL

                chmod +x $SANAGER_INSTALL_DIR/wp-cli.phar
                mv $SANAGER_INSTALL_DIR/wp-cli.phar /usr/local/bin/wp-cli
            fi
        }

        aptInstall $PACKAGES $PHP_EXTENSIONS
        a2enmod rewrite && a2enmod vhost_alias
    }

    function openvpn {
        PACKAGES="openvpn network-manager-openvpn network-manager-openvpn-gnome network-manager-pptp  network-manager-pptp-gnome"

        aptInstall $PACKAGES
        wordpressCli
    }

    # screen capture
    function obsStudio {
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F425E228 # key can be found at https://launchpad.net/~obsproject/+archive/ubuntu/obs-studio
        aptUpdate
        aptInstall obs-studio
    }

    function rabbitVCS {
        PACKAGES="rabbitvcs-core python-caja"
        aptInstall $PACKAGES
        cp "$SCRIPT_DIR/data/caja/RabbitVCS.py" ~/.local/share/caja-python/extensions/
    }

    aptInstall $PACKAGES $OFFICE
    sublimeText
    nodejs
    yarnpkg
    lamp
    openvpn
    obsStudio
    rabbitVCS
}

function fun {
    PACKAGES="vlc transmission easytag"
    PLAY_ON_LINUX="playonlinux ttf-mscorefonts-installer"

    function steam {
        PACKAGES="steam"

        dpkg --add-architecture i386
        aptInstall $PACKAGES
    }

    function rhythmbox {
        PACKAGES="rhythmbox rhythmbox-plugin-llyrics"
        REPO_ROW="deb http://ppa.launchpad.net/fossfreedom/rhythmbox-plugins/ubuntu $NOWADAYS_UBUNTU_VERSION main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/rhytmbox-plugins.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F4FE239D # key can be found at https://launchpad.net/~fossfreedom/+archive/ubuntu/rhythmbox
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
            aptInstall $PACKAGES
        fi

        aptInstall $PACKAGES
    }

    aptInstall $PACKAGES $PLAY_ON_LINUX
    rhythmbox
}


###############################################################################
# Main procedure
###############################################################################

essential
desktopDisplayEtc
virtualboxGuest
userEssential
work
fun


###############################################################################
# Post run cleansing
###############################################################################

apt-get $VERBOSE_APT_FLAG -f install # make sure all dependencies are met
apt-get $VERBOSE_APT_FLAG autoremove # remove any unused packages
