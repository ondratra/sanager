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
    pkg_audio
    pkg_fonts
    pkg_networkManager
    pkg_versioningAndTools
    pkg_sshServer
}

function homeServer_userMinimum {
    pkg_userEssential
    pkg_diskUtils
    effect_enableHistorySearch
    effect_enableBashCompletion
    effect_restoreMateConfig
}

function homeServer_userRobust {
    pkg_sublimeText
    pkg_multimedia
    pkg_zellij
    pkg_kittyTerminal
    pkg_terminalImprovements
}

function homeServer_physical {
    if isVirtualboxVm; then
        return
    fi

    pkg_amdCpuDrivers
    pkg_amdGpuDrivers

    pkg_hardwareAnalysis
    #pkg_corectrl # not available in stable repos atm
}

function homeServer_zfs {
    pkg_zfsLuks
}

function homeServer_advancedNetworking {
    pkg_syncthing
}
