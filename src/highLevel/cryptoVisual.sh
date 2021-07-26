
# TODO
source $SCRIPT_DIR/src/highLevel/pc.sh

function runHighLevel {
    pc_essentials
    pc_userMinimum

    versioningAndTools
    sublimeText

    restoreMateConfig # restore config (there might be icons for newly installed programs)
}
