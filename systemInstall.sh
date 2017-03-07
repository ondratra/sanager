#!/bin/bash
# see README.md for script description

# used when importing ubuntu packages
NOWADAYS_UBUNTU_VERSION="xenial"
SANAGER_INSTALL_DIR="/opt/sanagerInstall"

if [[ "$SUDO_USER" == "" ]]; then
    TMP='`sudo -E '$0'`'
    echo "You should run this script as regular user. Run: $TMP"
    echo "It's the only way to use your ssh keys for git auth, etc."
    exit 1;
fi

SCRIPT_EXECUTING_USER=$SUDO_USER
SCRIPT_DIR="`dirname \"$0\"`" # relative
SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized

VERBOSE_SCRIPT=`[[ "$1" == "--verbose" ]] && echo 1 || echo 0`
VERBOSE_APT_FLAG=`[[ "$VERBOSE_SCRIPT" == "1" ]] && echo "" || echo "-qq"`
VERBOSE_WGET_FLAG=`[[ "$VERBOSE_SCRIPT" == "0" ]] && echo "" || echo "-q"`

function printMsg {
    echo "SANAGER: $@"
}

function aptUpdate {
    printMsg "Updating repository cache"
    apt-get update $VERBOSE_APT_FLAG
}

function aptInstall {
    printMsg "Installing packages: $@"
    DEBIAN_FRONTEND="noninteractive" apt-get install "$VERBOSE_APT_FLAG" -y $@
}

function dpkgInstall {
    printMsg "Installing packages(dpkg): $@"
    if [ $VERBOSE_SCRIPT ]; then
        dpkg -i $@
    else
        dpkg -i $@ > /dev/null
    fi
}

function wgetDownload {
    printMsg "Downloading files via wget: $@"
    wget --no-hsts $VERBOSE_WGET_FLAG $@
}




function essential {
    PACKAGES="apt-transport-https aptitude"

    aptInstall $PACKAGES
}

function desktopDisplayEtc {
    PACKAGES="xorg pulseaudio"
    DESKTOP="mate mate-desktop-environment mate-desktop-environment-extras"
    DISPLAY="lightdm"
    DESKTOP_APPS="network-manager network-manager-gnome"

    function ininalityFonts {
        PACKAGES="fontconfig-infinality"
        REPO_ROW="deb http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu $NOWADAYS_UBUNTU_VERSION main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/ininality-fonts.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E985B27B # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
            aptInstall $PACKAGES
        fi
    }

    aptInstall $PACKAGES $DESKTOP $DISPLAY $DESKTOP_APPS
    ininalityFonts
}

function userEssential {
	PACKAGES="wget curl vim htop firefox chromium disk-manager"

    # enables bash histroy search by PageUp and PageDown keys
    function enableHistorySearch {
        # works system wide (changing /etc/inputrc)
        sed -e '/.*\(history-search-backward\|history-search-forward\)/s/^# //g' /etc/inputrc > tmpSadReplacementFile && mv tmpSadReplacementFile /etc/inputrc
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

    aptInstall $PACKAGES
    enableHistorySearch
    dropbox
}

function work {
	PACKAGES="git meld virtualbox gimp"
	JAVASCRIPT="nodejs"
    OFFICE="thunderbird libreoffice"

	function sublimeText {
        OPT_DIR="$SANAGER_INSTALL_DIR/sublimeText"
        DEB_FILE="sublime-text_build-3126_amd64.deb"
        PACKAGE_CONTROL_DOWNLOAD_URL="https://packagecontrol.io/Package%20Control.sublime-package"
        CONFIG_DIR=~/.config/sublime-text-3

        mkdir $OPT_DIR -p
        cd $OPT_DIR

        if [ ! -f $DEB_FILE ]; then
            wgetDownload "https://download.sublimetext.com/$DEB_FILE"
            dpkgInstall $DEB_FILE

            INSTALLED_PACKAGES_DIR="$CONFIG_DIR/Installed Packages"
            PACKAGE_LOCAL_NAME="Ondratra"
            FILES_TO_SYMLINK=("Preferences.sublime-settings" "Default (Linux).sublime-keymap" "SideBarEnhancements")

            # download editor's configuration and setup everything
            sudo -u $NON_ROOT_USERNAME mkdir $CONFIG_DIR -p
            mkdir $INSTALLED_PACKAGES_DIR -p
            mkdir "$CONFIG_DIR/Packages/User" -p
            cp "$SCRIPT_DIR/data/sublimeText" "$CONFIG_DIR/Packages/$PACKAGE_LOCAL_NAME" -r
            for TMP_FILE in "${FILES_TO_SYMLINK[@]}"; do
                ln -s "../$PACKAGE_LOCAL_NAME/$TMP_FILE" "$CONFIG_DIR/Packages/User/$TMP_FILE"
            done
            # download package control for sublime text -> it will download all other packages on first run
            wgetDownload --directory-prefix "$INSTALLED_PACKAGES_DIR" $PACKAGE_CONTROL_DOWNLOAD_URL
            # pass folder permission to relevant user
            chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_DIR
        fi
    }

    function yarnpkg {
        PACKAGES="yarn"
        REPO_ROW="deb https://dl.yarnpkg.com/debian/ stable main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/yarn.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            curl -sS "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add -
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
            aptInstall $PACKAGES
        fi
    }

    # Linux Apache MySQL PHP
    function lamp {
       PACKAGES="mysql-server apache2 php libapache2-mod-php php-curl php-gd php-mysql php-json php-soap"

       aptInstall $PACKAGES
       a2enmod rewrite && a2enmod vhost_alias
    }

    aptInstall $PACKAGES $JAVASCRIPT $OFFICE
    sublimeText
    yarnpkg
    lamp
}

function fun {
	PACKAGES="vlc transmission"
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
            sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F4FE239D # key can be found at https://launchpad.net/~fossfreedom/+archive/ubuntu/rhythmbox
            echo $REPO_ROW > $SOURCE_LIST_PATH
            aptUpdate
            aptInstall $PACKAGES
        fi

        aptInstall $PACKAGES
    }

	aptInstall $PACKAGES $PLAY_ON_LINUX
    rhythmbox
}

essential
desktopDisplayEtc
userEssential
work
fun


apt-get $VERBOSE_APT_FLAG -f install # make sure all dependencies are met
apt-get $VERBOSE_APT_FLAG autoremove # remove any unused packages
