
# (my) personal computer

function runHighLevel {
    pc_all
}

function pc_all {
    pc_essentials

    pc_userMinimum
    pc_userRobust
    pc_work
    pc_fun
    pc_userRobust
}

function pc_essentials {
    essential
    desktopDisplayEtc
    infinalityFonts
    networkManager
}

function pc_userMinimum {
    userEssential
    enableHistorySearch
    enableBashCompletion
    restoreMateConfig
}

function pc_userRobust {
    dropbox
    #pdfshuffle # TODO: this packages is likely gone - find substitute (?)
    datovka
}

function pc_work {
    versioningAndTools
    officePack
    sublimeText
    nodejs
    yarnpkg
    #lamp # no need for lamp lately
    openvpn
    obsStudio
    rabbitVCS


    #unity3d
    #godotEngine
    #heroku
}

function pc_fun {
    multimedia
    steam
    rhythmbox
    playOnLinux
}
