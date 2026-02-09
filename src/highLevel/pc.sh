# (my) personal computer

source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    pc_all
}

function pc_all {
    graphicalDesktop_all

    pc_essentials
    pc_userRobust
    pc_work
    pc_workInstantMessaging
    pc_fun
    pc_userRobust
    pc_advancedNetworking

    effect_restoreMateConfig
}

function pc_essentials {
    pkg_audio
    pkg_fonts
    pkg_networkManager
    pkg_diskUtils
}

function pc_userRobust {
    # TODO: make dropbox work - it unpredictably throws http error 404 when downloading install package and that breaks tests
    #  dropboxPackage
    pkg_pdftools
    # TODO: make datovka work - it currently depends on obsolete `libssl1.0.0` that is no longer available in Debian sid
    #pkg_datovka
    pkg_brave

    pkg_kittyTerminal

    pkg_ferdium
    pkg_keepass

    pkg_obsidian
}

function pc_work {
    # essentials
    pkg_versioningAndToolsGui
    pkg_officePack
    pkg_sublimeText

    # containerization
    pkg_docker

    # networking
    pkg_openvpn

    # programming
    pkg_yarn
    pkg_rust
    pkg_nodejs
    pkg_npm
    #pkg_lamp # no need for lamp lately
    pkg_rabbitVCS

    # video
    pkg_obsStudio

    #pkg_unity3d
    #pkg_godotEngine
    #pkg_heroku
}

function pc_workInstantMessaging {
    #pkg_keybase
    #pkg_slack
    pkg_discord
    pkg_signal
    pkg_telegram
}

function pc_fun {
    pkg_multimedia
    pkg_multimediaGui
    pkg_steam
    pkg_rhythmbox
    # TODO: uncomment this when lutris works - currently there is some incompatibility with `libasound-plugins:386` in sid
    #pkg_lutris
}

function pc_advancedNetworking {
    pkg_syncthing
}
