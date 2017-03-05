#!/bin/bash

# should work on most Debian-like distribution(tested on Debian and Ubuntu)

# Use
# `sudo -E`
# run this script on regular user account with -E ensures your git keeps, etc. will be available

# not handeled by this script
# - running `sudo apt-get update` before script
# - adding user to sudo; use `adduser yourNonRootUserName sudo` as root to do so

# script is meant to be non-destructive when run repeatedly
# script has no fail handeling -> when problem occurs fix it manually and update script



# used when importing ubuntu packages
NOWADAYS_UBUNTU_VERSION="xenial"
SANAGER_INSTALL_DIR="/opt/sanagerInstall"
SUBLIME_TEXT_GIT="git@git.ondratra.eu:ondratra/sublime-text-ondratra.git"

USER_RUNNING_SCRIPT=$SUDO_USER

function essential {
    PACKAGES="apt-transport-https"

    apt-get install $PACKAGES
}

function desktopDisplayEtc {
    PACKAGES="xorg pulseaudio"
    DESKTOP="mate mate-desktop-environment mate-desktop-environment-extras"
    DISPLAY="lightdm"
    # TODO: mb nemo?
    #DESKTOP_APPS="gnome-terminal"
    DESKTOP_APPS="network-manager network-manager-gnome"

    function ininalityFonts {
        PACKAGES="fontconfig-infinality"
        REPO_ROW="deb http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu $NOWADAYS_UBUNTU_VERSION main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/ininality-fonts.list"

        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E985B27B # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa
        echo $REPO_ROW > $SOURCE_LIST_PATH
        apt-get update
        apt-get install $PACKAGES
    }

    apt-get install $PACKAGES $DEKSTOP $DISPLAY $DESKTOP_APPS
    ininalityFonts
}

function userEssential {
	PACKAGES="wget curl vim htop firefox chromium disk-manager"

    function enableHistorySearch {
        # works system wide (changing /etc/inputrc)
        sed -e '/.*\(history-search-backward\|history-search-forward\)/s/^# //g' /etc/inputrc > tmpSadReplacementFile && mv tmpSadReplacementFile /etc/inputrc
    }

    apt-get install $PACKAGES
    enableHistorySearch
}

function work {
	PACKAGES="git meld"
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
            wget "https://download.sublimetext.com/$DEB_FILE"
            dpkg -i $DEB_FILE

            INSTALLED_PACKAGES_DIR="$CONFIG_DIR/Installed Packages"
            PACKAGE_LOCAL_NAME="Ondratra"
            mkdir $INSTALLED_PACKAGES_DIR -p
            mkdir "$CONFIG_DIR/Packages/User" -p
            git clone $SUBLIME_TEXT_GIT "$CONFIG_DIR/Packages/$PACKAGE_LOCAL_NAME"
            ln -s "../$PACKAGE_LOCAL_NAME/Preferences.sublime-settings" "$CONFIG_DIR/Packages/User/Preferences.sublime-settings"
            ln -s "../$PACKAGE_LOCAL_NAME/Default (Linux).sublime-keymap" "$CONFIG_DIR/Packages/User/Default (Linux).sublime-keymap"
            wget --directory-prefix "$INSTALLED_PACKAGES_DIR" $PACKAGE_CONTROL_DOWNLOAD_URL
            chown -R "$USER_RUNNING_SCRIPT:$USER_RUNNING_SCRIPT" $CONFIG_DIR
        fi
    }

    function yarnpkg {
        PACKAGES="yarn"
        REPO_ROW="deb https://dl.yarnpkg.com/debian/ stable main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/yarn.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            curl -sS "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add -
            echo $REPO_ROW > $SOURCE_LIST_PATH
            apt-get update
            apt-get install $PACKAGES
        fi
    }

    # Linux Apache MySQL PHP
    function lamp {
       PACKAGES="apache2 php7"
    }

    apt-get install $PACKAGES $JAVASCRIPT $OFFICE
    sublimeText
    yarnpkg
}

function fun {
	PACKAGES="vlc transmission steam"
    PLAY_ON_LINUX="playonlinux ttf-mscorefonts-installer"

    function rhythmbox {
        PACKAGES="rhythmbox rhythmbox-plugin-llyrics"
        REPO_ROW="deb http://ppa.launchpad.net/fossfreedom/rhythmbox-plugins/ubuntu $NOWADAYS_UBUNTU_VERSION main"
        SOURCE_LIST_PATH="/etc/apt/sources.list.d/rhytmbox-plugins.list"

        if [ ! -f $SOURCE_LIST_PATH ]; then
            sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F4FE239D # key can be found at https://launchpad.net/~fossfreedom/+archive/ubuntu/rhythmbox
            echo $REPO_ROW > $SOURCE_LIST_PATH
            apt-get update
            apt-get install $PACKAGES
        fi

        apt-get install $PACKAGES
    }

	apt-get install $PACKAGES $PLAY_ON_LINUX
    rhythmbox
}

essential
desktopDisplayEtc
userEssential
work
fun

