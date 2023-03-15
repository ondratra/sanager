
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

    hardwareAnalysis
    restoreMateConfig # restore config (there might be icons for newly installed programs)
    #changeMysqlPassword ""
}

function physicalPc_drivers {
    newestLinuxKernel

    # TODO: make cpu and gpu vendors configurable(?)
    amdCpuDrivers
    amdGpuDrivers
}

function physicalPc_cooling {
    corectrl
    coolercontrol
}

function physicalPc_virtualization {
    virtualbox
}

function physicalPc_screen {
    redshift
}
