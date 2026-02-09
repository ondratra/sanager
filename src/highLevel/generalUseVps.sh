# general use VPS without graphical interface

source $SCRIPT_DIR/src/highLevel/terminal.sh

function runHighLevel {
    terminal_all

    pkg_sshServer
    pkg_nodejs
    pkg_yarn
    pkg_lamp

    # TODO:
    # - gitlab (including Mattermost)
    # - forgejo?
    # - mail server (postfix, dovecot)
    # - certbot + cronjobs for him
}
