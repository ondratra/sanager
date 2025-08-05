# (my) personal computer

source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    pc_all
}

function pc_all {
    graphicalDesktop_all

    pc_essentials
    pc_userMinimum
    pc_userRobust
    pc_work
    pc_workInstantMessaging
    pc_fun
    pc_userRobust
    pc_advancedNetworking
}

function pc_essentials {
    audio
    fonts
    networkManager
}

function pc_userMinimum {
    userEssential
    diskUtils
    enableHistorySearch
    enableBashCompletion
    restoreMateConfig
}

function pc_userRobust {
    # TODO: make dropbox work - it unpredictably throws http error 404 when downloading install package and that breaks tests
    #  dropboxPackage
    pdftools
    # TODO: make datovka work - it currently depends on obsolete `libssl1.0.0` that is no longer available in Debian sid
    #datovka
    brave

    zellij
    kittyTerminal
    terminalImprovements

    ferdium_pkg
    keepass_pkg

    obsidian
}

function pc_work {
    # essentials
    versioningAndTools
    officePack
    sublimeText

    # networking
    openvpn

    # programming
    yarn
    rust
    nodejs_pkg
    npm_pkg
    #lamp # no need for lamp lately
    rabbitVCS

    # video
    obsStudio

    #unity3d
    #godotEngine
    #heroku
}

function pc_workInstantMessaging {
    #keybase
    #slack
    discord
    signal
}

function pc_fun {
    multimedia
    steam
    rhythmbox
    # TODO: uncomment this when lutris works - currently there is some incompatibility with `libasound-plugins:386` in sid
    #lutris
}

function pc_advancedNetworking {
    syncthing_pkg
}
