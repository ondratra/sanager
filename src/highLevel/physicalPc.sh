source $SCRIPT_DIR/src/highLevel/pc.sh

# (my) personal computer instaled on real world hardware

function runHighLevel {
    physicalPc_all
}

function physicalPc_all {
    pc_all

    physicalPc_drivers
    physicalPc_virtualization
    physicalPc_screen
    physicalPc_cooling

    pkg_hardwareAnalysis
    pkg_2dPrint
    effect_restoreMateConfig # restore config (there might be icons for newly installed programs)
    #effect_changeMysqlPassword ""
}

function physicalPc_drivers {
    if isVirtualboxVm; then
        return
    fi

    # TODO: make cpu and gpu vendors configurable(?)
    pkg_amdCpuDrivers
    pkg_amdGpuDrivers
}

function physicalPc_cooling {
    effect_setupTempSensors

    pkg_corectrl
    pkg_coolercontrol
}

function physicalPc_virtualization {
    pkg_virtualbox
    pkg_sanager_tests_prerequisities
}

function physicalPc_screen {
    pkg_redshift
}
