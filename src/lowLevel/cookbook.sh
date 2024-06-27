#!/bin/bash
# see README.md for script description

function installSanagerGlobally {
    EXECUTABLE_PATH=/usr/bin/sanager

    rm -rf $EXECUTABLE_PATH
    ln -s "$SCRIPT_DIR/systemInstall.sh" $EXECUTABLE_PATH
}

function essential {
    PACKAGES="apt-transport-https apt-listbugs aptitude wget net-tools bash-completion p7zip-full build-essential gdebi"
    DIRMNGR="dirmngr" # there might be glitches with gpg without dirmngr -> ensure it's presence

    aptGetInstall $PACKAGES $DIRMNGR
}

function infinalityFonts {
    PACKAGES="fontconfig-infinality"
    REPO_ROW="deb http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com E985B27B` # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa

    addAptRepository infinalityFonts "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES

    # in some situation you might need to run manually
    # sudo bash /etc/fonts/infinality/infctl.sh setstyle
    # and select 3) linux from the menu
}


function networkManager {
    PACKAGES="network-manager network-manager-gnome"

    # see https://wiki.debian.org/NetworkManager#Wired_Networks_are_Unmanaged
    applyPatch /etc/NetworkManager/NetworkManager.conf < $SCRIPT_DIR/data/misc/NetworkManager.conf.diff || PATCH_PROBLEM=$?

    if [[ "$PATCH_PROBLEM" == "0" ]]; then
        systemctl restart NetworkManager
    fi

    aptGetInstall $PACKAGES
}

function desktopDisplayEtc {
    PACKAGES="dconf-cli"
    XORG="xorg"
    DESKTOP="mate mate-desktop-environment mate-desktop-environment-extras mate-tweak"
    DISPLAY="lightdm"


    aptGetInstall $XORG # run this first separately to prevent D-bus init problems
    aptGetInstall $PACKAGES $DESKTOP $DISPLAY
}

function audio {
    PACKAGES="pulseaudio pulseeffects lsp-plugins"

    aptGetInstall $PACKAGES
}

function amdCpuDrivers {
    PACKAGES="firmware-linux-nonfree"
    #firmware-linux-nonfree is proprietary microcode - needed in current version of debian for free driver to work

    aptGetInstall $PACKAGES
}

function amdGpuDrivers {
    PACKAGES="xserver-xorg-video-ati mesa-va-drivers"

    aptGetInstall $PACKAGES
}

function virtualboxGuest {
    #PACKAGES="virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms"
    PACKAGES="virtualbox-guest-utils virtualbox-guest-x11"
    if [[ "$IS_VIRTUALBOX_GUEST" == "0" ]]; then
        return
    fi

    aptGetInstall $PACKAGES
}



# enables bash history search by PageUp and PageDown keys
function enableHistorySearch {
    # works system wide (changing /etc/inputrc)
    sed -e '/.*\(history-search-backward\|history-search-forward\)/s/^# //g' /etc/inputrc > tmpSedReplacementFile && mv tmpSedReplacementFile /etc/inputrc
}

function enableBashCompletion {
    applyPatch /etc/bash.bashrc < $SCRIPT_DIR/data/misc/bash.bashrc.diff || true
}

# TODO: improve cookbook's recipes naming or way how to invoke them
#       `dropbox` here conflicts with `dropbox` command that is installed
#       that makes ``dropbox start -i` call recursively calling this (install) function`
# TODO: make dropbox work - it unpredictably throws http error 404 when downloading install package and that breaks tests
#       NOTE: possibly not an issue anymore since `dropbox` from external repository has been replaced by `caja-dropbox`
function dropboxPackage {
    PACKAGES="caja-dropbox"

    aptGetInstall $PACKAGES

    dropbox start -i
}

function restoreMateConfig {
    function downloadTheme {
        THEME_URL="https://codeload.github.com/rtlewis88/rtl88-Themes/zip/refs/heads/Arc-Darkest-Nord-Frost"
        THEME_INTER_FOLDER="rtl88-Themes-Arc-Darkest-Nord-Frost"
        THEME_SUBFOLDER="Arc-Darkest-Nord-Frost"
        THEME_OUTPUT_FILE="$THEME_INTER_FOLDER.zip"

        if [ -d ~/.themes/$THEME_SUBFOLDER ]; then
            return
        fi

        # extract theme in temporary folder
        mkdir -p tmp/theme
        cd tmp
        wgetDownload "$THEME_URL" -O "$THEME_OUTPUT_FILE"
        7z x "$THEME_OUTPUT_FILE" -o"./theme"
        cp -rf "./theme/$THEME_INTER_FOLDER/$THEME_SUBFOLDER" ~/.themes/
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" ~/.themes/$THEME_SUBFOLDER

        # clean tmp folder
        cd ..
        rm tmp -r
    }

    function recomposeConfig {
        local PARTS_DIR="$1"
        local OUTPUT_FILE="$2"

        local FILE_PATHS=`find "$PARTS_DIR" -type f -name "*.txt" | sed -e "s/\.txt$//" | sort | sed -e "s/$/.txt/"`

        echo -n "" > $OUTPUT_FILE
        local FIRST_LINE="1"
        for FILE in $FILE_PATHS; do
            if [[ $FIRST_LINE == "1" ]]; then
                FIRST_LINE="0"
            else
                echo >> $OUTPUT_FILE
            fi

            cat "${FILE}" >> $OUTPUT_FILE
        done
    }

    local OUTPUT_FILE="$SCRIPT_DIR/data/mate/config.txt"
    local PARTS_DIR="$SCRIPT_DIR/data/mate/parts"

    recomposeConfig $PARTS_DIR $OUTPUT_FILE
    chown "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $OUTPUT_FILE

    downloadTheme

    # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
    sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS dconf load /org/mate/ < "$SCRIPT_DIR/data/mate/config.txt"
}

function userEssential {
    PACKAGES="curl vim htop iotop-c firefox chromium gnome-disk-utility"

    aptGetInstall $PACKAGES
}

function sublimeText {
    OPT_DIR="$SANAGER_INSTALL_DIR/sublimeText"
    DEB_FILE="sublime-text_build-4169_amd64.deb"
    PACKAGE_CONTROL_DOWNLOAD_URL="https://packagecontrol.io/Package%20Control.sublime-package"
    CONFIG_DIR=~/.config/sublime-text-3

    function ensureInstall {
        # download and install package if absent
        if [ -f $DEB_FILE ]; then
            return
        fi

        wgetDownload "https://download.sublimetext.com/$DEB_FILE"
        dpkgInstall $DEB_FILE
    }

    function refreshConfiguration {
        INSTALLED_PACKAGES_DIR="$CONFIG_DIR/Installed Packages"
        PACKAGE_LOCAL_NAME="Ondratra"
        FILES_TO_SYMLINK=("Preferences.sublime-settings" "Default (Linux).sublime-keymap" "SideBarEnhancements" "Package Control.sublime-settings" "Package Control.user-ca-bundle")

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
    ensureInstall
    refreshConfiguration
}


# newest version of nodejs (not among Debian packages yet)
function nodejs {
    PACKAGES="nodejs"
    REPO_ROW="deb https://deb.nodesource.com/node_18.x $NOWADAYS_DEBIAN_VERSION main"
    REPO_KEY_URL="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"

    addAptRepository nodejs "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function rust {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

function yarn {
    PACKAGES="yarnpkg"

    aptGetInstall $PACKAGES

    addAlias yarn yarnpkg

    function disableTelemetry {
        # TODO: check the status and prevent this setup of unnecessary tmp repository if telemetry is already disabled

        # NOTE: setup of dummy yarn repository is needed to disable telemetry
        #       see https://github.com/yarnpkg/yarn/issues/8882#issuecomment-1443786491 for more info
        local YARN_TEMP_DIR="$SANAGER_INSTALL_TEMP_DIR/myTestRepo"
        mkdir -p $YARN_TEMP_DIR
        cd $YARN_TEMP_DIR
        yarnpkg init -y
        yarnpkg set version berry

        # now telemetry can be finally disabled (other settings can be possibly set up here)
        yarnpkg config set --home enableTelemetry false

        rm -r $YARN_TEMP_DIR
    }

    disableTelemetry
}

# Linux Apache MySQL PHP
function lamp {
    # subversion(svn) is needed by some composer(https://getcomposer.org/) packages, etc.
    # it must be installed even when not directly used by system users
    PACKAGES="mysql-server apache2 php libapache2-mod-php subversion"
    PHP_EXTENSIONS="php-curl php-gd php-mysql php-pdo-pgsql php-json php-soap php-apcu php-xml php-mbstring php-yaml"

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

function mongodb {
    PACKAGES="mongodb"

    aptGetInstall $PACKAGES
}

function heroku {
    PACKAGES="heroku"
    REPO_ROW="deb https://cli-assets.heroku.com/apt ./"
    REPO_KEY_URL="https://cli-assets.heroku.com/apt/release.key"

    addAptRepository heroku "$REPO_ROW" $REPO_KEY_URL

    aptInstall $PACKAGES
}

function firebase {
    npm install -g firebase-tools
}

function docker {
    PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    REPO_ROW="deb https://download.docker.com/linux/debian $NOWADAYS_DEBIAN_VERSION stable"
    REPO_KEY_URL="https://download.docker.com/linux/debian/gpg"

    addAptRepository docker "$REPO_ROW" $REPO_KEY_URL

    aptInstall $PACKAGES

    addUserToGroup "$SCRIPT_EXECUTING_USER" docker
}

function pdfarranger {
    PACKAGES="pdfarranger"

    aptGetInstall $PACKAGES
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
    while [[ "$TMP" != "0" ]]; do
        printMsg "waiting for MySQL server"
        (mysql <<< $SQL_QUERY && TMP="0") || TMP="1"
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

function wireguard {
    PACKAGES="wireguard"

    aptGetInstall $PACKAGES
}

# screen capture
function obsStudio {
    PACKAGES="obs-studio"

    aptGetInstall $PACKAGES
}

function rabbitVCS {
    PACKAGES="rabbitvcs-core python3-caja"
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
    #DEB_FILE="unity-editor_amd64-5.6.1xf1Linux.deb"
    #DOWNLOAD_HASH="6a86e542cf5c"

    #DEB_FILE="unity-editor_amd64-2017.1.1xf1Linux.deb"
    #DOWNLOAD_HASH="f4fc8fd4067d"

    DEB_FILE="unity-editor_amd64-5.5.1xf1Linux.deb"
    DOWNLOAD_HASH="f5287bef00ff"


    OPT_DIR="$SANAGER_INSTALL_DIR/unity3d"

    # TODO: this is not finished
    function androidSdk {
        PACKAGES="libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386"
        JAVA="default-jdk"
        SDK_ZIP_FILE="android-studio-ide-162.4069837-linux.zip"
        URL="https://dl.google.com/dl/android/studio/ide-zips/2.3.3.0/$SDK_ZIP_FILE"

        #http://dl-ssl.google.com/android/repository/tools_r25.2.5-linux.zip
        #https://docs.unity3d.com/Manual/AttachingMonoDevelopDebuggerToAnAndroidDevice.html

        if [ ! -f "$OPT_DIR/$SDK_ZIP_FILE" ]; then
            wgetDownload $URL -O "$OPT_DIR/$SDK_ZIP_FILE"
        fi

        aptInstall $PACKAGES $JAVA
    }

    mkdir $OPT_DIR -p
    cd $OPT_DIR
    if [ ! -f "$OPT_DIR/$DEB_FILE" ]; then
        wgetDownload "http://beta.unity3d.com/download/$DOWNLOAD_HASH/$DEB_FILE" -O "$OPT_DIR/$DEB_FILE"
    fi
    aptInstall "$OPT_DIR/$DEB_FILE"

    androidSdk
}

function godotEngine {
    APP_FILENAME="Godot_v2.1.4-stable_x11.64"
    ZIP_FILENAME="$APP_FILENAME.zip"
    OPT_DIR="$SANAGER_INSTALL_DIR/godot"
    OPT_TEMP_DIR="$SANAGER_INSTALL_TEMP_DIR/godot"
    VERSION="2.1.4"
    RESULT_APP_NAME="godotEngine_$VERSION"

    APP_PATH="$OPT_DIR/$APP_FILENAME"
    ZIP_PATH="$OPT_TEMP_DIR/$ZIP_FILENAME"

    mkdir $OPT_DIR -p
    mkdir $OPT_TEMP_DIR -p

    if [ ! -f "$ZIP_PATH" ]; then
        wgetDownload "https://downloads.tuxfamily.org/godotengine/$VERSION/$ZIP_FILENAME" -O "$ZIP_PATH"
    fi

    if [ ! -f "$APP_PATH" ]; then
        DESKTOP_DIR=$(xdg-user-dir DESKTOP)
        7z x "$ZIP_PATH" -o"$OPT_DIR"
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $OPT_DIR
        ln -s "$APP_PATH" "$DESKTOP_DIR/$RESULT_APP_NAME"
    fi
}

# requires manual wizard walk-through
function androidStudio {
    PACKAGES="lib32stdc++6"
    APP_FILENAME="android-studio-ide-181.5056338-linux"
    ZIP_FILENAME="$APP_FILENAME.zip"
    OPT_DIR="$SANAGER_INSTALL_DIR/androidStudio"
    OPT_TEMP_DIR="$SANAGER_INSTALL_TEMP_DIR/androidStudio"
    VERSION="3.2.1.0"

    APP_PATH="$OPT_DIR/android-studio"
    ZIP_PATH="$OPT_TEMP_DIR/$ZIP_FILENAME"

    mkdir $OPT_DIR -p
    mkdir $OPT_TEMP_DIR -p

    aptInstall $PACKAGES

    if [ ! -f "$ZIP_PATH" ]; then
        wgetDownload "https://dl.google.com/dl/android/studio/ide-zips/$VERSION/$ZIP_FILENAME" -O "$ZIP_PATH"
    fi

    if [ ! -d "$APP_PATH" ]; then
        7z x "$ZIP_PATH" -o"$OPT_DIR"
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $OPT_DIR
    fi

    # run this manually
    # "$APP_PATH/bin/studio.sh"
}

function datovka {
    PACKAGES="datovka"
    REPO_ROW="deb http://ppa.launchpad.net/cz.nic-labs/datovka/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com F9C59A45` # key can be found at https://launchpad.net/~cz.nic-labs/+archive/ubuntu/datovka

    addAptRepository datovka "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES
}

function versioningAndTools {
    PACKAGES="git subversion meld gimp yt-dlp"

    aptGetInstall $PACKAGES
}

function officePack {
    PACKAGES="libreoffice libreoffice-gtk3 thunderbird"

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

    # pre-accept license
    echo steam steam/question select "I AGREE" | sudo debconf-set-selections
    echo steam steam/license note '' | sudo debconf-set-selections

    aptGetInstall $PACKAGES

    # remove license pre-acceptance
    echo UNREGISTER steam/question | sudo debconf-communicate steam > /dev/null
    echo UNREGISTER steam/license | sudo debconf-communicate steam > /dev/null
}

function rhythmbox {
    # package rhythmbox-plugins is needed now because llyrics plugin itself doesn't install all dependencies needed for it to work
    PACKAGES="rhythmbox rhythmbox-plugins rhythmbox-plugin-llyrics libflac8 flac"
    REPO_ROW="deb http://ppa.launchpad.net/fossfreedom/rhythmbox-plugins/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com F4FE239D` # key can be found at https://launchpad.net/~fossfreedom/+archive/ubuntu/rhythmbox

    addAptRepository rhytmbox-plugins "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES
}

function lutris {
    PACKAGES="lutris dxvk"
    RECOMMANDED_PACKAGES="libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386"
    REPO_ROW="deb http://download.opensuse.org/repositories/home:/strycore/Debian_Unstable/ ./"
    REPO_KEY_URL="https://download.opensuse.org/repositories/home:/strycore/Debian_Unstable/Release.key"

    addAptRepository lutris "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES $RECOMMANDED_PACKAGES
}

function multimedia {
    PACKAGES="vlc transmission easytag ardour"

    aptGetInstall $PACKAGES
}

function newestLinuxKernel {
    KERNEL_VERSION="6.3.0-1"
    PACKAGES="linux-image-$KERNEL_VERSION-amd64 linux-headers-$KERNEL_VERSION-amd64"

    aptGetInstall $PACKAGES
}

function hardwareAnalysis {
    PACKAGES="hardinfo"

    aptGetInstall $PACKAGES
}

function distUpgrade {
    aptUpdate
    aptDistUpgrade
}

function distCleanup {
    aptFixDependencies
    aptCleanup
}

function redshift {
    PACKAGES="redshift-gtk"
    CONFIG_FILE_PATH=~/.config/redshift.conf

    if [ ! -f $CONFIG_FILE_PATH ]; then
        cp $SCRIPT_DIR/data/misc/redshift.conf $CONFIG_FILE_PATH
    fi

    aptGetInstall $PACKAGES
}

function brave {
    PACKAGES="brave-browser"
    REPO_ROW="deb https://brave-browser-apt-release.s3.brave.com/ stable main"
    REPO_KEY_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

    addAptRepository brave "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function keybase {
    PACKAGES="keybase"
    REPO_ROW="deb http://prerelease.keybase.io/deb stable main"
    REPO_KEY_URL="https://keybase.io/docs/server_security/code_signing_key.asc"

    addAptRepository keybase "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES

    # this file sometimes gets autogenerated but conflits Sanager's Keybase source
    rm -f /etc/apt/sources.list.d/keybase.list
}

function iridium {
    PACKAGES="iridium-browser"
    REPO_ROW="deb https://downloads.iridiumbrowser.de/deb/ stable main"
    REPO_KEY_URL="https://downloads.iridiumbrowser.de/ubuntu/iridium-release-sign-01.pub"

    addAptRepository iridium "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}


function slack {
    PACKAGES="slack-desktop"
    REPO_ROW="deb https://packagecloud.io/slacktechnologies/slack/debian/ jessie main"
    REPO_KEY_URL="https://slack.com/gpg/slack_pubkey_20210901.gpg"
    #REPO_KEY_URL=`gpgKeyUrlFromKeyring pgpkeys.mit.edu C6ABDCF64DB9A0B2` # TODO - automatically search for online keyservers
    REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com C6ABDCF64DB9A0B2`

    addAptRepository slack "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function signal {
    PACKAGES="signal-desktop"
    REPO_ROW="deb https://updates.signal.org/desktop/apt xenial main"
    REPO_KEY_URL="https://updates.signal.org/desktop/apt/keys.asc" # TODO - save and check key's checksum

    addAptRepository signal "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function zoom {
    PACKAGES_DEPENDENCIES=""
    OPT_DIR="$SANAGER_INSTALL_DIR/zoom"
    DEB_FILE="zoom_amd64.deb"

    mkdir $OPT_DIR -p
    cd $OPT_DIR

    if isInstalled "zoom"; then
        return 0
    fi

    aptGetInstall $PACKAGES_DEPENDENCIES

    if [ ! -f $DEB_FILE ]; then
        wgetDownload "https://zoom.us/client/latest/$DEB_FILE" -O $DEB_FILE
    fi

    # install package and auto-accept license (-n means non-interactive install)
    dpkgInstall -n $DEB_FILE
}

function obsidian {
    LATEST_VERSION="1.5.3"
    DEB_FILE=obsidian_${LATEST_VERSION}_amd64.deb
    OPT_DIR="$SANAGER_INSTALL_DIR/obsidian"

    mkdir $OPT_DIR -p
    cd $OPT_DIR

    if [ ! -f $DEB_FILE ]; then
        PACKAGE_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/$DEB_FILE"
        wgetDownload $PACKAGE_URL -O $DEB_FILE
    fi

    dpkgInstall $DEB_FILE
}

function corectrl {
    PACKAGES="corectrl"

    aptGetInstall $PACKAGES

    # enable autostart
    cp /usr/share/applications/org.corectrl.corectrl.desktop ~/.config/autostart/org.corectrl.corectrl.desktop

    cp $SCRIPT_DIR/data/misc/90-corectrl.rules /etc/polkit-1/rules.d/90-corectrl.rules
}

function coolercontrol {
    PACKAGES="coolercontrol"
    REPO_ROW="deb https://dl.cloudsmith.io/public/coolercontrol/coolercontrol/deb/debian $NOWADAYS_DEBIAN_VERSION main"
    REPO_KEY_URL="https://dl.cloudsmith.io/public/coolercontrol/coolercontrol/gpg.668189E5007F5A8D.key"

    addAptRepository coolercontrol "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES

    systemctl enable coolercontrold.service
    systemctl start coolercontrold.service
}

function discord {
    DEB_FILE=discord.deb
    OPT_DIR="$SANAGER_INSTALL_DIR/discord"

    mkdir $OPT_DIR -p
    cd $OPT_DIR

    if [ ! -f $DEB_FILE ]; then
        PACKAGE_URL="https://discord.com/api/download?platform=linux&format=deb"
        wgetDownload $PACKAGE_URL -O $DEB_FILE
    fi

    dpkgInstall $DEB_FILE
}

function dotnet_pkg {
    #PACKAGES="dotnet-sdk-6.0 dotnet-sdk-7.0" # installing dotnet-sdk-7.0 is problematic when developing dotnet 6.0 app
    PACKAGES="dotnet-sdk-6.0"
    REPO_ROW="deb https://packages.microsoft.com/debian/11/prod $NOWADAYS_DEBIAN_VERSION main"
    REPO_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"

    # disable telemetry - needs to happen before package install
    addGlobalEnvVariable dotnet "DOTNET_CLI_TELEMETRY_OPTOUT=true"

    addAptRepository dotnet "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES

    dotnet tool install --global dotnet-ef
}

function vscodium {
    PACKAGES="codium codium-insiders"
    REPO_ROW="deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main"
    REPO_KEY_URL="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg"

    addAptRepository vscodium "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function nix {
    INSTALL_FILE=install-nix.sh
    OPT_DIR="$SANAGER_INSTALL_DIR/nix"
    NIX_DIR="/nix"
    NIX_ETC_DIR="/etc/nix/"
    NIX_ETC_CONFIG="/etc/nix/nix.conf"

    mkdir $OPT_DIR -p
    cd $OPT_DIR

    # ensure /nix folder exists
    mkdir -m 0755 -p /nix
    chown $SCRIPT_EXECUTING_USER /nix

    if [ ! -f $INSTALL_FILE ]; then
        PACKAGE_URL="https://nixos.org/nix/install"
        wgetDownload $PACKAGE_URL -O $INSTALL_FILE

        chmod +x $INSTALL_FILE
        sudo -u $SCRIPT_EXECUTING_USER ./$INSTALL_FILE # run install file
    fi

    # setup flake feature
    mkdir -p $NIX_ETC_DIR
    > $NIX_ETC_CONFIG # create empty config file
    echo "experimental-features = nix-command flakes" >> $NIX_ETC_CONFIG
    echo "allow-import-from-derivation = true" >> $NIX_ETC_CONFIG

    # manually add nix to current terminal
    # . /home/ondratra/.nix-profile/etc/profile.d/nix.sh
}

function zellij {
    PACKAGES="xclip"
    OPT_DIR="$SANAGER_INSTALL_DIR/zellij"
    CONFIG_DIR=~/.config/zellij

    INSTALL_FILE="zellij-x86_64-unknown-linux-musl.tar.gz"
    BINARY_URL="https://github.com/zellij-org/zellij/releases/download/v0.39.2/$INSTALL_FILE"

    function ensureInstall {
        # download and install package if absent
        if [ -f $INSTALL_FILE ]; then
            return
        fi

        wgetDownload "https://download.sublimetext.com/$DEB_FILE"
        dpkgInstall $DEB_FILE
    }

    function refreshConfiguration {
        # setup configuration
        cp "$SCRIPT_DIR/data/zellij" "$CONFIG_DIR" -rT

        # pass folder permission to relevant user
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_DIR
    }

    mkdir $OPT_DIR -p
    cd $OPT_DIR

    aptGetInstall $PACKAGES
    ensureInstall
    refreshConfiguration
}

# TODO:
# - IMPORTANT!!!
#   - create apt policy file in preferences.d/ for each added repository
#   - save hash(es) (Merkle Tree?) of all used/downloaded gpg keys in this repository so any changes are spotted
# - reenable lamp (maybe a fix for mysql password init problems will be needed)
# - iridium - update to some 2022 version (?)
# - Element instant messaging
# - teamviewer (?)
# - check `logseq` if it's valid replacement to obsidian
# - NextCloud or OwnCloud or something similar
# - consider using `wmctrl` to create script(s) for starting all usual programs on specific desktop workspace(s)
# - opendoas + rework this script to use it - should be simple, but replacement for `sudo -E` usage must be found first
# - rename install functions in cookbook - there is a problem with a install function, for example, `yarn` and the utility of same name
#   if you call `yarn` inside of cookbook, you will mistakenly call install function + you can cause infinite loop when calling
#   `yarn` the utility inside of `yarn` the install function
# - create utility function `runAsRegularUser userName commandToRun...` that will abstract `sudo -u ...` and `sudo -u sh -c ...`
# - unite wgetDownload calls - make it download files to sanager install dir, make calls use same number of parameters, etc.
#   - add new feature that will check if file is already downloaded and skip the download if it's so - bacically move this
#     this behaviour into the function instead of doing it on each/most call of this function
# - NICE TO HAVE - autocomplete/suggestion in bash when calling `sudo -E ./systemInstall.sh XXX [YYY]`
# - create helper function to handle `mkdir $OPT_DIR -p; cd $OPT_DIR` etc. calls for creating package's install dir (and downloading install file if needed)
# - ensure that `apt-get dist-upgrade -y` doesn't install broken packages as reported by `apt-listbugs` during `apt-get dist-upgrade`
#   - create a new function that somehow upgrades everything except broken packages reported by `apt-listbugs`
# - save/load prefered applications / file associations and make it easily editable
# - unite calling of pattern `mkdir $XXX && doSomething $XXX `chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $XXX`
