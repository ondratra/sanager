
source ./pc.sh

# (my) personal computer instaled on real world hardware

function runHighLevel {
    physicalPc_all
}

function physicalPc_all {
    pc_all
    physicalPc_virtualization
}

function physicalPc_virtualization {
    virtualbox
}
