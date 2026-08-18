source $SCRIPT_DIR/src/highLevel/terminal.sh

function runHighLevel {
    serviceNest_all
}

function serviceNest_all {
    terminal_all

    serviceNest_essentials
    serviceNest_advancedNetworking
}

function serviceNest_essentials {
    pkg_sshServer
    pkg_versioningAndTools
}

function serviceNest_advancedNetworking {
    pkg_networkFileShareClient
    pkg_firewall
}
