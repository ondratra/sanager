source $SCRIPT_DIR/src/highLevel/graphicalDesktop.sh

function runHighLevel {
    graphicalDesktop_all

    aiServer_codingTools
    aiServer_aiServices
}

function aiServer_codingTools {
    pkg_nodejs
    pkg_npm
    pkg_rust
    pkg_yarn
    pkg_docker
}

function aiServer_aiServices {
    pkg_aiServers
    pkg_aiCodingCli

    effect_installOllamaModels
}
