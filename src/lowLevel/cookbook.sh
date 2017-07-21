#!/bin/bash
# see README.md for script description

function essential {
    PACKAGES="apt-transport-https aptitude wget net-tools bash-completion"
    DIRMNGR="dirmngr" # there might be glitches with gpg without dirmngr -> ensure it's presence

    aptGetInstall $PACKAGES $DIRMNGR
}


function ininalityFonts {
    PACKAGES="fontconfig-infinality"
    REPO_ROW="deb http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    SOURCE_LIST_PATH="/etc/apt/sources.list.d/ininality-fonts.list"

    if [ ! -f $SOURCE_LIST_PATH ]; then
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E985B27B # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa
        echo $REPO_ROW > $SOURCE_LIST_PATH
        aptUpdate
        aptGetInstall $PACKAGES
    fi

    # in some situation you might need to run manually
    # sudo bash /etc/fonts/infinality/infctl.sh setstyle
    # and select 3) linux from the menu
}


function networkManager {
    PACKAGES="network-manager network-manager-gnome"

    # see https://wiki.debian.org/NetworkManager#Wired_Networks_are_Unmanaged
    applyPatch /etc/NetworkManager/NetworkManager.conf < $SCRIPT_DIR/data/misc/NetworkManager.conf.diff
    PATCH_PROBLEM=$?

    if [[ "$PATCH_PROBLEM" == "0" ]]; then
        systemctl restart network-manager
    fi
    aptGetInstall $PACKAGES
}

function desktopDisplayEtc {
    PACKAGES="pulseaudio dconf-cli"
    XORG="xorg"
    DESKTOP="mate mate-desktop-environment mate-desktop-environment-extras"
    DISPLAY="lightdm"


    aptGetInstall $XORG # run this first separately to prevent D-bus init problems
    aptGetInstall $PACKAGES $DESKTOP $DISPLAY
}


function amdDrivers {
    PACKAGES="firmware-linux-nonfree xserver-xorg-video-ati"
    #firmware-linux-nonfree is proprietary microcode - needed in current version of debian for free driver to work

    aptGetInstall $PACKAGES
}


function virtualboxGuest {
    if [[ "$IS_VIRTUALBOX_GUEST" == "0" ]]; then
        return
    fi

    aptGetInstall virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms
}



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
        aptGetInstall $PACKAGES
        wgetDownload "https://www.dropbox.com/download?dl=packages/debian/$DEB_FILE" -O $DEB_FILE
        dpkgInstall $DEB_FILE
        dropbox start -i
    fi
}

function restoreMateConfig {
    # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
    sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS dconf load /org/mate/ < "$SCRIPT_DIR/data/mate/config.txt"
}

function userEssential {
    PACKAGES="curl vim htop firefox chromium disk-manager"

    aptGetInstall $PACKAGES
}

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

    aptGetInstall $PACKAGES
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

    # there exists some 'yarn' command in 'cmdtest' package - not used so get rid of it
    aptRemove cmdtest
    aptGetInstall $PACKAGES
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

    MYSQL_NEEDS_RESET="1"
    if isInstalled "mysql-server"; then
        MYSQL_NEEDS_RESET="0"
    fi

    aptGetInstall $PACKAGES $PHP_EXTENSIONS
    a2enmod rewrite && a2enmod vhost_alias
    wordpressCli
    usermod -a -G www-data $SCRIPT_EXECUTING_USER

    if [[ $MYSQL_NEEDS_RESET == "1" ]]; then
        changeMysqlPassword ""
    fi
}

function changeMysqlPassword {
    NEW_PASSWORD="$1"
    echo "newPassword: '$1'"
    TMP_FILE="$SANAGER_INSTALL_DIR/tmp.sql"
    SQL_QUERY="FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$NEW_PASSWORD'; FLUSH PRIVILEGES; SHUTDOWN;";

    systemctl stop mysql > /dev/null 2> /dev/null

    mkdir -p /var/run/mysqld
    chown mysql:mysql /var/run/mysqld
    mysqld_safe --skip-grant-tables &

    # make sure query is accpeted by server(aka server is running)
    TMP="1"
    echo $TMP
    while [[ "$TMP" != "0" ]]; do
        printMsg "waiting for MySQL server"
        mysql <<< $SQL_QUERY
        TMP="$?"
        sleep 1
    done
    systemctl start mysql

    # fix tables after dirty MySQL import (copying /var/lib/mysql folder instead of using `mysqldump`)
    # mysqlcheck -u [username] -p --all-databases --check-upgrade --auto-repair
}

function openvpn {
    PACKAGES="openvpn network-manager-openvpn network-manager-openvpn-gnome network-manager-pptp  network-manager-pptp-gnome"

    aptGetInstall $PACKAGES
}

# screen capture
function obsStudio {
    if isInstalled obs-studio; then
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F425E228 # key can be found at https://launchpad.net/~obsproject/+archive/ubuntu/obs-studio
        aptUpdate
    fi
    aptGetInstall obs-studio
}

function rabbitVCS {
    PACKAGES="rabbitvcs-core python-caja"
    EXTENSION_DIR=~/.local/share/caja-python/extensions/
    FILENAME="RabbitVCS.py"

    aptGetInstall $PACKAGES

    # copy python extension to th right place
    if [ ! -f $EXTENSION_DIR ]; then
        mkdir $EXTENSION_DIR -p
    fi
    cp "$SCRIPT_DIR/data/caja/$FILENAME.template" "$EXTENSION_DIR/$FILENAME"
}

function unity3d {
    DEB_FILE="unity-editor_amd64-5.6.1xf1Linux.deb"
    OPT_DIR="$SANAGER_INSTALL_DIR/unity3d"

    mkdir $OPT_DIR -p
    cd $OPT_DIR
    if [ ! -f "$OPT_DIR/$DEB_FILE" ]; then
        wgetDownload "http://beta.unity3d.com/download/6a86e542cf5c/$DEB_FILE" -O "$OPT_DIR/$DEB_FILE"
    fi
    aptInstall "$OPT_DIR/$DEB_FILE"
}


function versioningAndTools {
    PACKAGES="git subversion meld gimp youtube-dl"

    aptGetInstall $PACKAGES
}

function officePack {
    PACKAGES="libreoffice thunderbird"

    aptGetInstall $PACKAGES
}

function virtualbox {
    PACKAGES="virtualbox"

    aptGetInstall $PACKAGES
}

# STEAM NOT WORKING RIGHT NOW - as proprietary licence you need to explicitly agree with licence -> without interactive mode it's auto decline
function steam {
    PACKAGES="steam"

    TMP=`dpkg --print-foreign-architectures`
    if [[ "$TMP" != "i386" ]]; then
        dpkg --add-architecture i386
        aptUpdate
    fi

    aptGetInstall $PACKAGES
}

function rhythmbox {
    PACKAGES="rhythmbox rhythmbox-plugin-llyrics"
    REPO_ROW="deb http://ppa.launchpad.net/fossfreedom/rhythmbox-plugins/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    SOURCE_LIST_PATH="/etc/apt/sources.list.d/rhytmbox-plugins.list"

    if [ ! -f $SOURCE_LIST_PATH ]; then
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F4FE239D # key can be found at https://launchpad.net/~fossfreedom/+archive/ubuntu/rhythmbox
        echo $REPO_ROW > $SOURCE_LIST_PATH
        aptUpdate
        aptGetInstall $PACKAGES
    fi

    aptGetInstall $PACKAGES
}

function playOnLinux {
    PACKAGES="playonlinux ttf-mscorefonts-installer libsm6:i386 libfreetype6:i386 libldap-2.4-2:i386 pulseaudio0:i386"

    TMP=`dpkg --print-foreign-architectures`
    if [[ "$TMP" != "i386" ]]; then
        dpkg --add-architecture i386
        aptUpdate
    fi

    aptGetInstall $PACKAGES
}

function multimedia {
    PACKAGES="vlc transmission easytag"

    aptGetInstall $PACKAGES
}

function newestLinuxKernel {
    PACKAGES="linux-image-4.11.0-1-amd64 linux-headers-4.11.0-1-amd64"

    aptGetInstall $PACKAGES
}

function hardwareAnalysis {
    PACKAGES="hardinfo"

    aptGetInstall $PACKAGES
}

function distroUpgrade {
    aptUpdate
    aptDistUpgrade
}