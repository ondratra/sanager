
# general use VPS without graphical interface

function runHighLevel {
    essential
    enableHistorySearch
    enableBashCompletion

    versioningAndTools
    nodejs
    yarn
    lamp

    # TODO:
    # - gitlab (including Mattermost)
    # - svn ? (legacy reasons)
    # - mail server (postfix, dovecot)
    # - certbot + cronjobs for him

}

