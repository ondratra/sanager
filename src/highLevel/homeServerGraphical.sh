source $SCRIPT_DIR/src/highLevel/homeServerTerminal.sh
source $SCRIPT_DIR/src/highLevel/mixins/physicalHardwareGraphical.sh

function runHighLevel {
    homeServerGraphical_all
}

function homeServerGraphical_all {
    homeServerTerminal_all
    mixin_physicalHardwareGraphical_all

    homeServerGraphical_userTools

    effect_restoreMateConfig
}

function homeServerGraphical_userTools {
    pkg_diskUtils

    pkg_sublimeText
    pkg_multimediaGui
    pkg_kittyTerminal
    pkg_remoteControlGui
}
