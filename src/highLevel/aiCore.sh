source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    graphicalDesktop_all

    aiCore_graphicalTooling
    aiCore_codingTools

    effect_restoreMateConfig # restore config (there might be icons for newly installed programs)
}

function aiCore_graphicalTooling {
    pkg_versioningAndToolsGui
    pkg_sublimeText
    pkg_kittyTerminal
    pkg_obsidian
}

function aiCore_codingTools {
    pkg_nodejs
    pkg_npm
    pkg_rust
    pkg_yarn
    pkg_docker

    pkg_aiCoding
}
