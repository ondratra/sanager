# (my) personal home server

source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    homeServer_all
}

function homeServer_all {
    homeServer_essentials
    homeServer_physical
    homeServer_userMinimum
    homeServer_userRobust
    homeServer_zfs
    homeServer_advancedNetworking
}

function homeServer_essentials {
    graphicalDesktop_all

    audio
    fonts
    networkManager
    versioningAndTools
    sshServer
}

function homeServer_userMinimum {
    userEssential
    diskUtils
    enableHistorySearch
    enableBashCompletion
    restoreMateConfig
}

function homeServer_userRobust {
    sublimeText
    multimedia
    zellij
    kittyTerminal
    terminalImprovements
}

function homeServer_physical {
    if is_virtualbox; then
        return
    fi

    amdCpuDrivers
    amdGpuDrivers

    hardwareAnalysis
    #corectrl # not available in stable repos atm
}

function homeServer_zfs {
    zfsLuks
}

function homeServer_advancedNetworking {
    syncthing_pkg
}
