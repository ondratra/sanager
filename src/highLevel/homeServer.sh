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
}

function homeServer_essentials {
    graphicalDesktop_all

    audio
    infinalityFonts
    networkManager
    versioningAndTools
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
    # TODO install zfs
    echo "TODO: zfs"
}
