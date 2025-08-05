# general use VPS without graphical interface

source $SCRIPT_DIR/src/highLevel/common.sh

function runHighLevel {
    common_all

    essential
    enableHistorySearch
    enableBashCompletion

    versioningAndTools
    nodejs_pkg
    yarn
    lamp

    # TODO:
    # - gitlab (including Mattermost)
    # - svn ? (legacy reasons)
    # - mail server (postfix, dovecot)
    # - certbot + cronjobs for him

}

