source $SCRIPT_DIR/src/highLevel/terminal.sh
source $SCRIPT_DIR/src/highLevel/pc.sh

function runHighLevel {
    graphicalDesktop_all

    pkg_diskUtils
    pkg_versioningAndToolsGui
    pkg_sublimeText

    effect_restoreMateConfig # restore config (there might be icons for newly installed programs)
}
