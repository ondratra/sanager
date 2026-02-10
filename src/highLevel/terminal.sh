function runHighLevel {
    terminal_all
}

function terminal_all {
    effect_divertCustomizedEtcConfigs

    pkg_newestLinuxKernel
    pkg_essential
    pkg_networkManager
    pkg_sshClient

    terminal_sanager
    terminal_terminalEnhancements

    pkg_versioningAndTools
    pkg_userEssential
    pkg_fonts
    pkg_zellij
}

function terminal_sanager {
    pkg_multimedia_necessary
    effect_installSanagerMedia
}

function terminal_terminalEnhancements {
    pkg_terminalImprovements

    effect_enableHistorySearch
    effect_enableBashCompletion
    effect_addPathToUserBinaries
    effect_setupShellPrompt
}
