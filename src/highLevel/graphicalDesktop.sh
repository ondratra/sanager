source $SCRIPT_DIR/src/highLevel/common.sh

function runHighLevel {
    graphicalDesktop_all
}

function graphicalDesktop_all {
    common_all

    essential
    desktopDisplayEtc

    newestLinuxKernel
}
