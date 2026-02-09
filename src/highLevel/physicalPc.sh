source $SCRIPT_DIR/src/highLevel/pc.sh
source $SCRIPT_DIR/src/highLevel/mixins/physicalHardwareGraphical.sh

# (my) personal computer instaled on real world hardware

function runHighLevel {
    physicalPc_all
}

function physicalPc_all {
    pc_all
    mixin_physicalHardwareGraphical_all

    pkg_2dPrint

    effect_restoreMateConfig
}
