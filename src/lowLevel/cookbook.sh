#!/bin/bash
# see README.md for script description

function pkg_essential {
    PACKAGES="apt-transport-https apt-listbugs aptitude wget net-tools bash-completion p7zip-full build-essential gdebi rsync ntpsec"
    DIRMNGR="dirmngr" # there might be glitches with gpg without dirmngr -> ensure it's presence

    aptGetInstall $PACKAGES $DIRMNGR
}

function pkg_fonts {
    #PACKAGES="fontconfig-infinality fonts-noto-color-emoji"
    PACKAGES="fonts-noto-color-emoji"
    MAX_UBUNTU_VERSION="xenial" # repository doesn't support newer Ubuntu versions atm
    #REPO_ROW="deb http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu $MAX_UBUNTU_VERSION main"
    #REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com E985B27B` # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa

    #addAptRepository infinalityFonts "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES

    # in some situation you might need to run manually
    # sudo bash /etc/fonts/infinality/infctl.sh setstyle
    # and select 3) linux from the menu
}

function pkg_networkManager {
    PACKAGES="network-manager network-manager-gnome"

    # see https://wiki.debian.org/NetworkManager#Wired_Networks_are_Unmanaged
    applyPatch /etc/NetworkManager/NetworkManager.conf < $SCRIPT_DIR/data/misc/NetworkManager.conf.diff || PATCH_PROBLEM=$?

    if [[ "$PATCH_PROBLEM" == "0" ]]; then
        systemctl restart NetworkManager
    fi

    aptGetInstall $PACKAGES
}

function pkg_desktopDisplayEtc {
    local PACKAGES="dconf-cli"
    local XORG="xorg"
    local DESKTOP="mate mate-desktop-environment mate-desktop-environment-extras mate-tweak"
    local DISPLAY="lightdm"

    aptGetInstall $XORG # run this first separately to prevent D-bus init problems
    aptGetInstall $PACKAGES $DESKTOP $DISPLAY
}

function pkg_audio {
    PACKAGES="pulseaudio pulseeffects lsp-plugins"

    aptGetInstall $PACKAGES
}

function pkg_amdCpuDrivers {
    PACKAGES="firmware-linux-nonfree"
    #firmware-linux-nonfree is proprietary microcode - needed in current version of debian for free driver to work

    aptGetInstall $PACKAGES
}

function pkg_amdGpuDrivers {
    PACKAGES="xserver-xorg-video-ati mesa-va-drivers"

    aptGetInstall $PACKAGES
}

function pkg_virtualboxGuest {
    #PACKAGES="virtualbox-guest-utils virtualbox-guest-x11 virtualbox-guest-dkms"
    PACKAGES="virtualbox-guest-utils virtualbox-guest-x11"

    if ! isVirtualboxVm; then
        return
    fi

    aptGetInstall $PACKAGES
}

# TODO: improve cookbook's recipes naming or way how to invoke them
#       `dropbox` here conflicts with `dropbox` command that is installed
#       that makes ``dropbox start -i` call recursively calling this (install) function`
# TODO: make dropbox work - it unpredictably throws http error 404 when downloading install package and that breaks tests
#       NOTE: possibly not an issue anymore since `dropbox` from external repository has been replaced by `caja-dropbox`
function pkg_dropboxPackage {
    PACKAGES="caja-dropbox"

    aptGetInstall $PACKAGES

    dropbox start -i
}


function pkg_userEssential {
    PACKAGES="curl vim htop iotop-c chromium"
    PACKAGE_FIREFOX=$(is_debian_sid && echo "firefox" || echo "firefox-esr")

    aptGetInstall $PACKAGES $PACKAGE_FIREFOX

    pkg_librewolf
}

function pkg_diskUtils {
    PACKAGES="gnome-disk-utility gparted"

    aptGetInstall $PACKAGES
}

function pkg_terminalImprovements {
    PACKAGES="fzf duf tailspin"

    aptGetInstall $PACKAGES
}

function pkg_2dPrint {
    PACKAGES="cups cups-browsed xsane simple-scan gscan2pdf"

    aptGetInstall $PACKAGES
    systemctl restart cups-browsed
}

function pkg_sublimeText {
    DEB_FILE="sublime-text_build-4200_amd64.deb"
    PACKAGE_URL="https://download.sublimetext.com/$DEB_FILE"
    PACKAGE_CONTROL_DOWNLOAD_URL="https://github.com/wbond/package_control/releases/download/4.0.8/Package.Control.sublime-package"
    CONFIG_DIR=~/.config/sublime-text

    function refreshConfiguration {
        INSTALLED_PACKAGES_DIR="$CONFIG_DIR/Installed Packages"
        PACKAGE_LOCAL_NAME="Ondratra"
        FILES_TO_SYMLINK=("Preferences.sublime-settings.symlinktarget" "Default (Linux).sublime-keymap.symlinktarget" "SideBarEnhancements" "Package Control.sublime-settings.symlinktarget" "Package Control.user-ca-bundle.symlinktarget")

        # download editor's configuration and setup everything
        sudo -u $SCRIPT_EXECUTING_USER mkdir $CONFIG_DIR -p
        mkdir "$INSTALLED_PACKAGES_DIR" -p
        mkdir "$CONFIG_DIR/Packages/User" -p
        cp "$SCRIPT_DIR/data/sublimeText" "$CONFIG_DIR/Packages/$PACKAGE_LOCAL_NAME" -rT

        # NOTE: my own theme depends on Soda theme being installed - use it if it's available.
        #       Otherwise keep theme commented out to prevent SublimeText from crashing on start
        if [ -f "$INSTALLED_PACKAGES_DIR/Theme - Soda.sublime-package" ]; then
            sed -i 's|^\( *\)//\("theme":\)|\1\2|' "$CONFIG_DIR/Packages/$PACKAGE_LOCAL_NAME/Preferences.sublime-settings.symlinktarget"
        fi

        # NOTE: symlinking package control settings wreak havoc to sublime -> resulted in removing all packages
        #       and then installing ALL packages available to package control; that's why all symlinked files have
        #       suffix `.symlinktarget` so they are ignored by Sublime Text on their own
        for TMP_FILE in "${FILES_TO_SYMLINK[@]}"; do
            TARGET_FILE_NAME="${TMP_FILE/.symlinktarget/}"
            ln -sfn "../$PACKAGE_LOCAL_NAME/$TMP_FILE" "$CONFIG_DIR/Packages/User/$TARGET_FILE_NAME"
        done

        # download package control when absent
        if [ ! -f "$INSTALLED_PACKAGES_DIR/Package Control.sublime-package" ]; then
            # download package control for sublime text -> it will download all other packages on first run
            wgetDownload $PACKAGE_CONTROL_DOWNLOAD_URL -O "$INSTALLED_PACKAGES_DIR/Package Control.sublime-package"
        fi

        # pass folder permission to relevant user
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_DIR
    }

    dpkgDownloadAndInstall sublimeText "$DEB_FILE" "$PACKAGE_URL"
    refreshConfiguration
}

# newest version of nodejs (not among Debian packages yet)
function pkg_nodejs {
    PACKAGES="nodejs"

    # uncomment and update when some version of node than available in Debian repositoriesis needed
    # ---
    #REPO_ROW="deb https://deb.nodesource.com/node_18.x $NOWADAYS_DEBIAN_VERSION main"
    #REPO_KEY_URL="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"

    #addAptRepository nodejs "$REPO_ROW" $REPO_KEY_URL
    # ---

    aptGetInstall $PACKAGES
}

function pkg_npm {
    PACKAGES="npm"

    aptGetInstall $PACKAGES
}

function pkg_rust {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u $SCRIPT_EXECUTING_USER sh -s -- -y
}

function pkg_yarn {
    PACKAGES="yarnpkg"

    aptGetInstall $PACKAGES

    addAlias yarn yarnpkg

    function disableTelemetry {
        return
        if [[ `yarnpkg config get enableTelemetry` == "false" ]]; then
            return
        fi

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
function pkg_lamp {
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

function pkg_mongodb {
    PACKAGES="mongodb-org"
    REPO_ROW="deb http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main"
    REPO_KEY_URL="https://www.mongodb.org/static/pgp/server-8.0.asc"

    addAptRepository mongodb "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES

    function installMongoDbCompass {
        OPT_DIR="$SANAGER_INSTALL_DIR/mongodb"
        VERSION="1.45.4"
        DEB_FILE="mongodb-compass_${VERSION}_amd64.deb"
        DEB_FILE_URL="https://downloads.mongodb.com/compass/${DEB_FILE}"

        if [ -f "$OPT_DIR/$DEB_FILE" ]; then
            return
        fi

        mkdir $OPT_DIR -p
        cd $OPT_DIR
        wgetDownload $DEB_FILE_URL -O "$OPT_DIR/$DEB_FILE"
        dpkgInstall $DEB_FILE
    }

    installMongoDbCompass
}

function pkg_heroku {
    PACKAGES="heroku"
    REPO_ROW="deb https://cli-assets.heroku.com/apt ./"
    REPO_KEY_URL="https://cli-assets.heroku.com/apt/release.key"

    addAptRepository heroku "$REPO_ROW" $REPO_KEY_URL

    aptInstall $PACKAGES
}

function pkg_firebase {
    npm install -g firebase-tools
}

function pkg_docker {
    PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
    REPO_ROW="deb https://download.docker.com/linux/debian $NOWADAYS_DEBIAN_VERSION stable"
    REPO_KEY_URL="https://download.docker.com/linux/debian/gpg"

    addAptRepository docker "$REPO_ROW" $REPO_KEY_URL

    aptInstall $PACKAGES

    addUserToGroup "$SCRIPT_EXECUTING_USER" docker

    function installLazydocker {
        VERSION="0.24.1"
        RELEASE_FILE="lazydocker_${VERSION}_Linux_x86_64.tar.gz"
        RELEASE_URL="https://github.com/jesseduffield/lazydocker/releases/download/v${VERSION}/${RELEASE_FILE}"
        OPT_DIR="$SANAGER_INSTALL_DIR/lazydocker"

        if [ -f "$OPT_DIR/$RELEASE_FILE" ]; then
            return
        fi

        mkdir $OPT_DIR -p
        cd $OPT_DIR
        wgetDownload $RELEASE_URL -O "$OPT_DIR/$RELEASE_FILE"
        tar -xzf $RELEASE_FILE

        echo "export PATH=\$PATH:$OPT_DIR" >> ~/.bashrc
    }

    installLazydocker
}

function pkg_pdftools {
    PACKAGES="pdfarranger img2pdf"

    aptGetInstall $PACKAGES
}

function pkg_pandoc {
    PACKAGES="pandoc"

    aptGetInstall $PACKAGES
}

function pkg_openvpn {
    PACKAGES="openvpn network-manager-openvpn network-manager-openvpn-gnome network-manager-pptp  network-manager-pptp-gnome"

    aptGetInstall $PACKAGES
}

function pkg_wireguard {
    PACKAGES="wireguard"

    aptGetInstall $PACKAGES
}

# screen capture
function pkg_obsStudio {
    PACKAGES="obs-studio"

    aptGetInstall $PACKAGES
}

function pkg_rabbitVCS {
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

function pkg_unity3d {
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

function pkg_godotEngine {
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
function pkg_androidStudio {
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

function pkg_datovka {
    PACKAGES="datovka"
    REPO_ROW="deb http://ppa.launchpad.net/cz.nic-labs/datovka/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com F9C59A45` # key can be found at https://launchpad.net/~cz.nic-labs/+archive/ubuntu/datovka

    addAptRepository datovka "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES
}

function pkg_versioningAndTools {
    PACKAGES="git subversion meld gimp yt-dlp"

    aptGetInstall $PACKAGES
}

function pkg_officePack {
    PACKAGES="libreoffice libreoffice-gtk3 thunderbird"

    aptGetInstall $PACKAGES
}

function pkg_virtualbox {
    PACKAGES="virtualbox"

    aptGetInstall $PACKAGES
}

function pkg_steam {
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

function pkg_rhythmbox {
    # package rhythmbox-plugins is needed now because llyrics plugin itself doesn't install all dependencies needed for it to work
    PACKAGES="rhythmbox rhythmbox-plugins libflac14 flac"

    # plugins for lyrics are disabled for now - launchpad has old signature (rsa1024)
    #PACKAGES="rhythmbox rhythmbox-plugins rhythmbox-plugin-llyrics libflac14 flac"
    #REPO_ROW="deb http://ppa.launchpad.net/fossfreedom/rhythmbox-plugins/ubuntu $NOWADAYS_UBUNTU_VERSION main"
    #REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com 143BC139DC5B097AA27C821B07089EBCF3AC1FCD` # key can be found at https://launchpad.net/~fossfreedom/+archive/ubuntu/rhythmbox-plugins

    #addAptRepository rhytmbox-plugins "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES
}

function pkg_lutris {
    PACKAGES="lutris dxvk"
    RECOMMANDED_PACKAGES="libgnutls30:i386 libldap-2.4-2:i386 libgpg-error0:i386 libxml2:i386 libasound2-plugins:i386 libsdl2-2.0-0:i386 libfreetype6:i386 libdbus-1-3:i386 libsqlite3-0:i386"
    REPO_ROW="deb http://download.opensuse.org/repositories/home:/strycore/Debian_Unstable/ ./"
    REPO_KEY_URL="https://download.opensuse.org/repositories/home:/strycore/Debian_Unstable/Release.key"

    addAptRepository lutris "$REPO_ROW" $REPO_KEY_URL

    aptGetInstall $PACKAGES $RECOMMANDED_PACKAGES
}

function pkg_multimedia {
    PACKAGES="vlc transmission easytag ardour ffmpeg mpv"

    aptGetInstall $PACKAGES
}

function pkg_newestLinuxKernel {
    KERNEL_VERSION=$(is_debian_sid && echo "6.12.33+deb13" || echo "6.1.0-26")
    PACKAGES="linux-image-$KERNEL_VERSION-amd64 linux-headers-$KERNEL_VERSION-amd64"

    aptGetInstall $PACKAGES
}

function pkg_hardwareAnalysis {
    PACKAGES="hardinfo"

    aptGetInstall $PACKAGES
}

function pkg_redshift {
    PACKAGES="redshift-gtk"
    CONFIG_FILE_PATH=~/.config/redshift.conf

    if [ ! -f $CONFIG_FILE_PATH ]; then
        cp $SCRIPT_DIR/data/misc/redshift.conf $CONFIG_FILE_PATH
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_FILE_PATH
    fi

    aptGetInstall $PACKAGES

    autostartApplication "redshift-gtk.desktop"
}

function pkg_brave {
    PACKAGES="brave-browser"
    REPO_ROW="deb https://brave-browser-apt-release.s3.brave.com/ stable main"
    REPO_KEY_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

    addAptRepository brave "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

# keybase not supported for now due to obsolete repo signature (SHA1)
#function keybase {
#    PACKAGES="keybase"
#    REPO_ROW="deb http://prerelease.keybase.io/deb stable main"
#    REPO_KEY_URL="https://keybase.io/docs/server_security/code_signing_key.asc"
#
#    addAptRepository keybase "$REPO_ROW" $REPO_KEY_URL
#    aptGetInstall $PACKAGES
#
#    # this file sometimes gets autogenerated but conflits Sanager's Keybase source
#    rm -f /etc/apt/sources.list.d/keybase.list
#}

# slack not supported for now due to obsolete repo signature (SHA1)
#function slack {
#    PACKAGES="slack-desktop"
#    REPO_ROW="deb https://packagecloud.io/slacktechnologies/slack/debian/ jessie main"
#    REPO_KEY_URL="https://slack.com/gpg/slack_pubkey_20210901.gpg"
#    #REPO_KEY_URL=`gpgKeyUrlFromKeyring pgpkeys.mit.edu C6ABDCF64DB9A0B2` # TODO - automatically search for online keyservers
#    REPO_KEY_URL=`gpgKeyUrlFromKeyring keyserver.ubuntu.com C6ABDCF64DB9A0B2`
#
#    #addAptRepository slack "$REPO_ROW" $REPO_KEY_URL
#    #aptGetInstall $PACKAGES
#}

function pkg_signal {
    PACKAGES="signal-desktop"
    REPO_ROW="deb https://updates.signal.org/desktop/apt xenial main"
    REPO_KEY_URL="https://updates.signal.org/desktop/apt/keys.asc" # TODO - save and check key's checksum

    addAptRepository signal "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function pkg_zoom {
    PACKAGES_DEPENDENCIES=""
    DEB_FILE="zoom_amd64.deb"
    PACKAGE_URL="https://zoom.us/client/latest/$DEB_FILE"

    aptGetInstall $PACKAGES_DEPENDENCIES
    dpkgDownloadAndInstall zoom "$DEB_FILE" "$PACKAGE_URL"
}

function pkg_obsidian {
    LATEST_VERSION="1.8.9"
    DEB_FILE=obsidian_${LATEST_VERSION}_amd64.deb
    PACKAGE_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/$DEB_FILE"

    dpkgDownloadAndInstall obsidian "$DEB_FILE" "$PACKAGE_URL"
}

function pkg_corectrl {
    PACKAGES="corectrl"

    aptGetInstall $PACKAGES

    autostartApplication "org.corectrl.CoreCtrl.desktop"

    local GROUP=`id -gn $SCRIPT_EXECUTING_USER`
    sed -e "s|__\$GROUP__|$GROUP|g" $SCRIPT_DIR/data/misc/90-corectrl.rules > /etc/polkit-1/rules.d/90-corectrl.rules
}

function pkg_coolercontrol {
    PACKAGES="coolercontrol"
    REPO_ROW="deb https://dl.cloudsmith.io/public/coolercontrol/coolercontrol/deb/debian $NOWADAYS_DEBIAN_VERSION main"
    REPO_KEY_URL="https://dl.cloudsmith.io/public/coolercontrol/coolercontrol/gpg.668189E5007F5A8D.key"
    CONFIG_DIR=~/.config/coolercontrol

    function refreshConfiguration {
        # setup configuration
        cp "$SCRIPT_DIR/data/coolercontrol" "$CONFIG_DIR" -rT

        # pass folder permission to relevant user
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_DIR
    }

    addAptRepository coolercontrol "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
    refreshConfiguration

    systemctl enable coolercontrold.service
    systemctl start coolercontrold.service
}

function pkg_discord {
    DEB_FILE=discord.deb
    PACKAGE_URL="https://discord.com/api/download?platform=linux&format=deb"

    dpkgDownloadAndInstall discord "$DEB_FILE" "$PACKAGE_URL"
}

function pkg_dotnet {
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

function pkg_vscodium {
    PACKAGES="codium codium-insiders"
    REPO_ROW="deb https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main"
    REPO_KEY_URL="https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg"

    addAptRepository vscodium "$REPO_ROW" $REPO_KEY_URL
    aptGetInstall $PACKAGES
}

function pkg_nix {
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
    # . ~/.nix-profile/etc/profile.d/nix.sh
}

function pkg_zellij {
    PACKAGES="xclip"
    OPT_DIR="$SANAGER_INSTALL_DIR/zellij"
    CONFIG_DIR=~/.config/zellij
    CURRENT_VERSION="v0.41.2"

    INSTALL_FILE="zellij-x86_64-unknown-linux-musl.tar.gz"
    BINARY_URL="https://github.com/zellij-org/zellij/releases/download/$CURRENT_VERSION/$INSTALL_FILE"

    function ensureInstall {
        # download and install package if absent
        if [ -f $INSTALL_FILE ]; then
            return
        fi

        wgetDownload $BINARY_URL
        tar -xzf $INSTALL_FILE

        # TODO: consider using addGlobalEnvVariable instead or create some resusable utility function
        # TODO:
        #    - improve this -> don't insert multiple `export PATH=...` into bashrc file
        #    - manual calling `source ~/.bashrc` is needed in each terminal before usage
        echo "export PATH=\$PATH:$OPT_DIR" >> ~/.bashrc
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

# after running this for first time, manually setup /etc/sanoid/sanoid.conf and /etc/systemd/system/syncoind.service
function pkg_zfsLuks {
    PACKAGES="zfsutils-linux cryptsetup"

    aptGetInstall $PACKAGES

    # see https://github.com/jimsalterjrs/sanoid/blob/master/INSTALL.md#debianubuntu
    function buildSanoidPackage {
        OPT_DIR="$SANAGER_INSTALL_DIR/sanoid"
        SANOID_DEPENDENCIES="debhelper libcapture-tiny-perl libconfig-inifiles-perl pv lzop mbuffer"

        aptGetInstall $SANOID_DEPENDENCIES

        if [ -d $OPT_DIR ]; then
           return
        fi

        git clone https://github.com/jimsalterjrs/sanoid.git $OPT_DIR
        cd $OPT_DIR

        # checkout latest stable release or stay on master for bleeding edge stuff (but expect bugs!)
        #git checkout $(git tag | grep "^v" | tail -n 1)
        git checkout 6beef5fee67deb2c17f160244953bd5a1983e1ad # (https://github.com/jimsalterjrs/sanoid/commit/6beef5fee67deb2c17f160244953bd5a1983e1ad)
        ln -s packages/debian .
        dpkg-buildpackage -uc -us
        aptInstall ../sanoid_*_all.deb

        systemctl enable sanoid --now
    }

    function setupSanoid {
        CONFIG_NAME=sanoid.conf
        CONFIG_SOURCE_PATH=$SCRIPT_DIR/data/sanoid/$CONFIG_NAME
        CONFIG_TARGET_PATH=/etc/sanoid/$CONFIG_NAME

        if [ -f $CONFIG_TARGET_PATH ]; then
           return
        fi

        cp -rf $CONFIG_SOURCE_PATH $CONFIG_TARGET_PATH

        # manually adjust the config now - /etc/sanoid/sanoid.conf - specificaly for your machine

        systemctl enable sanoid --now
    }

    function setupSyncoid {
        CONFIG_NAME=syncoid.service
        CONFIG_SOURCE_PATH=$SCRIPT_DIR/data/sanoid/$CONFIG_NAME
        CONFIG_TARGET_PATH=/etc/systemd/system/$CONFIG_NAME

        CONFIG_NAME_TIMER=syncoid.timer
        CONFIG_SOURCE_PATH_TIMER=$SCRIPT_DIR/data/sanoid/$CONFIG_NAME_TIMER
        CONFIG_TARGET_PATH_TIMER=/etc/systemd/system/$CONFIG_NAME_TIMER

        if [ -f $CONFIG_TARGET_PATH ]; then
           return
        fi

        cp -rf $CONFIG_SOURCE_PATH $CONFIG_TARGET_PATH
        cp -rf $CONFIG_SOURCE_PATH_TIMER $CONFIG_TARGET_PATH_TIMER

        systemctl daemon-reload
        systemctl enable --now syncoid.timer
    }

    buildSanoidPackage
    setupSanoid
    setupSyncoid
}

function pkg_sshServer {
    PACKAGES="openssh-server"

    aptGetInstall $PACKAGES

    CONFIG_NAME="__sanagerConfig.conf"
    CONFIG_SOURCE_PATH=$SCRIPT_DIR/data/sshServer/$CONFIG_NAME
    CONFIG_TARGET_PATH=/etc/ssh/sshd_config.d/$CONFIG_NAME

    if [ -f $CONFIG_TARGET_PATH ]; then
       return
    fi

    cp -rf $CONFIG_SOURCE_PATH $CONFIG_TARGET_PATH
}

function pkg_kittyTerminal {
    PACKAGES="kitty"
    CONFIG_SOURCE_FOLDER=$SCRIPT_DIR/data/kitty
    CONFIG_TARGET_PATH=~/.config/kitty

    aptGetInstall $PACKAGES

    if [ -f "$CONFIG_TARGET_PATH/kitty.conf" ]; then
        return
    fi

    mkdir $CONFIG_TARGET_PATH -p
    cp -rp $CONFIG_SOURCE_FOLDER/* $CONFIG_TARGET_PATH/
    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_TARGET_PATH
}

function pkg_syncthing {
    PACKAGES="syncthing"
    CONFIG_SOURCE_FOLDER=$SCRIPT_DIR/data/syncthing
    CONFIG_TARGET_PATH=~/.local/state/syncthing
    CONFIG_XML_PATH=$CONFIG_TARGET_PATH/config.xml

    aptGetInstall $PACKAGES

    if [ -f $CONFIG_XML_PATH ]; then
        return
    fi

    mkdir -p /mnt/syncthing

    syncthing generate --no-default-folder
    THIS_MACHINE_DEVICE_ID=$(sed -n 's/^    <device id="\([^"]*\)".*/\1/p' $CONFIG_XML_PATH)
    THIS_MACHINE_NAME=$(uname -n)

    # overwrite generated config
    cat $CONFIG_SOURCE_FOLDER/config.xml \
        | sed "s/\${THIS_MACHINE_DEVICE_ID}/$THIS_MACHINE_DEVICE_ID/g" \
        | sed "s/\${THIS_MACHINE_NAME}/$THIS_MACHINE_NAME/g" \
        > $CONFIG_XML_PATH

    # now manually update config if -> configure listening address, devices, and folders
    # for each Syncthing folder, put symlinks into `/mnt/syncthing/myShareWithMachineXyz` pointing to local folders
    # you want to share

    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_TARGET_PATH
    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" ~/.local/state

    # ensure user's deamon doesn't deactivate on logout
    loginctl enable-linger $SCRIPT_EXECUTING_USER

    # TODO: create a helper function for using systemctl as regular user
    sudo -u $SCRIPT_EXECUTING_USER  XDG_RUNTIME_DIR="/run/user/$(id -u $SCRIPT_EXECUTING_USER)" systemctl --user enable syncthing
    sudo -u $SCRIPT_EXECUTING_USER  XDG_RUNTIME_DIR="/run/user/$(id -u $SCRIPT_EXECUTING_USER)" systemctl --user start syncthing
}

function pkg_extrepo {
    PACKAGES="extrepo"

    aptGetInstall $PACKAGES
}

function pkg_librewolf {
    pkg_extrepo

    PACKAGES="librewolf"

    if ! isExtrepoRepositoryEnabled librewolf; then
        extrepo enable $PACKAGES
        aptUpdate
    fi
    aptGetInstall $PACKAGES
}

function pkg_ferdium {
    LATEST_VERSION="7.1.0"
    DEB_FILE=Ferdium-linux-${LATEST_VERSION}-amd64.deb
    PACKAGE_URL="https://github.com/ferdium/ferdium-app/releases/download/v${LATEST_VERSION}/$DEB_FILE"

    dpkgDownloadAndInstall ferdium "$DEB_FILE" "$PACKAGE_URL"
}

function pkg_keepass {
    PACKAGES="keepassxc"
    CONFIG_SOURCE_FOLDER=$SCRIPT_DIR/data/keepassxc
    CONFIG_TARGET_PATH=~/.config/keepassxc

    aptGetInstall $PACKAGES

    if [ -f "$CONFIG_TARGET_PATH/keepassxc.ini" ]; then
        return
    fi

    mkdir $CONFIG_TARGET_PATH -p
    cp -rp $CONFIG_SOURCE_FOLDER/* $CONFIG_TARGET_PATH/
    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $CONFIG_TARGET_PATH
}

# TODO:
# - IMPORTANT!!!
#   - create apt policy file in preferences.d/ for each added repository
#   - save hash(es) (Merkle Tree?) of all used/downloaded gpg keys in this repository so any changes are spotted
# - reenable lamp (maybe a fix for mysql password init problems will be needed)
# - Element instant messaging
# - teamviewer (?)
# - check `logseq` if it's valid replacement to obsidian
# - NextCloud or OwnCloud or something similar
# - consider using `wmctrl` to create script(s) for starting all usual programs on specific desktop workspace(s)
# - opendoas + rework this script to use it - should be simple, but replacement for `sudo -E` usage must be found first
# - rename install functions in cookbook - there is a problem with a install function, for example, `yarn` and the utility of same name
#   if you call `yarn` inside of cookbook, you will mistakenly call install function + you can cause infinite loop when calling
#   `yarn` the utility inside of `yarn` the install function (same situation will dotnet, syncthing, etc)
# - create utility function `runAsRegularUser userName commandToRun...` that will abstract `sudo -u ...` and `sudo -u sh -c ...`
# - unite wgetDownload calls - make it download files to sanager install dir, make calls use same number of parameters, etc.
#   - add new feature that will check if file is already downloaded and skip the download if it's so - bacically move this
#     this behaviour into the function instead of doing it on each/most call of this function
# - NICE TO HAVE - autocomplete/suggestion in bash when calling `sudo -E ./systemInstall.sh XXX [YYY]`
# - ensure that `apt-get dist-upgrade -y` doesn't install broken packages as reported by `apt-listbugs` during `apt-get dist-upgrade`
#   - create a new function that somehow upgrades everything except broken packages reported by `apt-listbugs`
# - save/load prefered applications / file associations and make it easily editable
# - unite calling of pattern `mkdir $XXX && doSomething $XXX `chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $XXX`
# - create a mechanism for installing binary files -> look at zellij and lazydocker -> it likely should create
#   `/opt/__sanager/bin`, link or add binaries there, and add it to PATH via `.bashrc`
# - isolate Steam from rest of system - it's proprietary software installing other proprietary system
