source $SCRIPT_DIR/src/highLevel/common.sh

function runHighLevel {
    graphicalDesktop_all
}

function graphicalDesktop_all {
    common_all

    pkg_essential
    pkg_desktopDisplayEtc

    pkg_newestLinuxKernel
}
