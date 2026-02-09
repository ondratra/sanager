source $SCRIPT_DIR/src/highLevel/terminal.sh
source $SCRIPT_DIR/src/highLevel/mixins/physicalHardwareTerminal.sh

function runHighLevel {
    homeServerTerminal_all
}

function homeServerTerminal_all {
    terminal_all
    mixin_physicalHardwareTerminal_all

    homeServerTerminal_essentials
    homeServerTerminal_zfs
    homeServerTerminal_advancedNetworking
}

function homeServerTerminal_essentials {
    pkg_sshServer
    pkg_audio
    pkg_versioningAndToolsGui
    pkg_multimedia
}

function homeServerTerminal_zfs {
    pkg_zfsLuks
}

function homeServerTerminal_advancedNetworking {
    pkg_syncthing
}
