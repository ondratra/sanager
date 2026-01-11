# general use VPS without graphical interface

source $SCRIPT_DIR/src/highLevel/common.sh

function runHighLevel {
    common_all

    pkg_versioningAndTools
    pkg_nodejs
    pkg_yarn
    pkg_lamp

    # TODO:
    # - gitlab (including Mattermost)
    # - svn ? (legacy reasons)
    # - mail server (postfix, dovecot)
    # - certbot + cronjobs for him

}

