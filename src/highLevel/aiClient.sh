source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh
source $SCRIPT_DIR/src/highLevel/aiServer.sh

function runHighLevel {
    graphicalDesktop_all

    aiClient_codingCli
    aiClient_graphicalTooling

    effect_restoreMateConfig # restore config (there might be icons for newly installed programs)
}

function aiClient_codingCli {
    pkg_docker
    pkg_aiCodingCli
}

function aiClient_graphicalTooling {
    pkg_versioningAndToolsGui
    pkg_sublimeText
    pkg_kittyTerminal
    pkg_obsidian
}
