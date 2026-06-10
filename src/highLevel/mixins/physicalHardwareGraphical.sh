source $SCRIPT_DIR/src/highLevel/mixins/physicalHardwareTerminal.sh

function mixin_physicalHardwareGraphical_all {
    mixin_physicalHardwareTerminal_all

    mixin_physicalHardwareGraphical_screen
    mixin_physicalHardwareGraphical_disks
    mixin_physicalHardwareGraphical_cooling
}

function mixin_physicalHardwareGraphical_screen {
    pkg_redshift
    pkg_hardwareAnalysis
}

function mixin_physicalHardwareGraphical_disks {
    pkg_diskUtilsGui
}

function mixin_physicalHardwareGraphical_cooling {
    pkg_corectrl
    pkg_coolercontrol
}
