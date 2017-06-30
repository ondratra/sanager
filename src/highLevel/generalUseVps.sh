
# general use VPS without graphical interface

function runHighLevel {
    essential
    enableHistorySearch
    enableBashCompletion

    versioningAndTools
    nodejs
    yarnpkg
    lamp

    # TODO:
    # - gitlab (including Mattermost)
    # - svn ? (legacy reasons)
    # - mail server (postfix, dovecot)
    # - certbot + cronjobs for him

}

