source $SCRIPT_DIR/src/highLevel/mixins/physicalHardwareTerminal.sh

function mixin_physicalHardwareGraphical_all {
    mixin_physicalHardwareTerminal_all

    mixin_physicalHardwareGraphical_screen
}

function mixin_physicalHardwareGraphical_screen {
    pkg_redshift
    pkg_hardwareAnalysis
}
