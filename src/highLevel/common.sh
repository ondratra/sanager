function runHighLevel {
    common_all
}

function common_all {
    pkg_newestLinuxKernel
    pkg_essential

    pkg_multimedia_necessary
    effect_installSanagerMedia

    # improve terminal
    effect_enableHistorySearch
    effect_enableBashCompletion
    effect_setupShellPrompt
}
