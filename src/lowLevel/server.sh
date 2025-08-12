# TODO

# GitLab
# mail server (posix, dovecot)

function pkg_certbot {
    local PACKAGES="python3 python3-venv libaugeas0"

    aptGetInstall $PACKAGES

    local CERBOT_DIR=$SANAGER_INSTALL_DIR/certbot
    local PIP_PATH=$CERBOT_DIR/bin/pip

    python3 -m venv $CERBOT_DIR/
    $PIP_PATH install --upgrade pip
    $PIP_PATH install certbot certbot-apache

    ln -s $CERBOT_DIR/bin/certbot /usr/bin/certbot
    ln -s $CERBOT_DIR/bin/certbot /usr/sbin/certbot
}
