
# (my) personal computer

source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    pc_all
}

function pc_all {
    pc_essentials

    pc_userMinimum
    pc_userRobust
    pc_work
    pc_workInstantMessaging
    pc_fun
    pc_userRobust
}

function pc_essentials {
    graphicalDesktop_all

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
    # TODO: make dropbox work - it unpredictably throws http error 404 when downloading install package and that breaks tests
    #  dropboxPackage
    pdfarranger
    # TODO: make datovka work - it currently depends on obsolete `libssl1.0.0` that is no longer available in Debian sid
    #datovka
    brave
    #iridium
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
    nodejs
    #lamp # no need for lamp lately
    rabbitVCS

    # video
    obsStudio

    #unity3d
    #godotEngine
    #heroku
}

function pc_workInstantMessaging {
    keybase
    slack
}

function pc_fun {
    multimedia
    # TODO: uncomment this when steam works - currently there is some incompatibility with `libedit2` in sid
    #steam
    rhythmbox
    # TODO: uncomment this when lutris works - currently there is some incompatibility with `libasound-plugins:386` in sid
    #lutris
}
