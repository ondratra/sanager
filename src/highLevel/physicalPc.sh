
source $SCRIPT_DIR/src/highLevel/pc.sh

# (my) personal computer instaled on real world hardware

function runHighLevel {
    physicalPc_all
}

function physicalPc_all {
    pc_all
    physicalPc_drivers
    physicalPc_virtualization

    hardwareAnalysis
    restoreMateConfig # restore config (there might be icons for newly installed programs)
    #changeMysqlPassword ""
}

function physicalPc_drivers {
    newestLinuxKernel
    amdDrivers
}

function physicalPc_virtualization {
    virtualbox
}
