# (my) personal home server

source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    homeServer_all
}

function homeServer_all {
    graphicalDesktop_all

    homeServer_essentials
    homeServer_physical
    homeServer_userMinimum
    homeServer_userRobust
    homeServer_zfs
    homeServer_advancedNetworking
}

function homeServer_essentials {
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
    if isVirtualboxVm; then
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
