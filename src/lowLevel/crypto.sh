
# TODO

# ethereum
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E985B27B # key can be found at https://launchpad.net/~no1wantdthisname/+archive/ubuntu/ppa

# btc, etc

# NOTE: when running this script from ubuntu-like system you shouldn't use default repository
#       see https://www.torproject.org/docs/tor-relay-debian.html.en
#       pure debian is fine
function tor {
    PACKAGES="ntp tor"

    aptGetInstall $PACKAGES

    # TODO uncomment line:
    # #ExitPolicy reject *:* # no exits allowed
    systemctl restart tor
}

function monero {
    PACKAGES="monero-wallet-gui libxcb-image0 libxcb-iccm4 libxcb-keysims1 libxcb-render-util0 libxcb-xkb1 libxkbcommon-x11 libxkbcommon-x11-0"

    wget https://www.whonix.org/patrick.asc
    sudo apt-key --keyring /etc/apt/trusted.gpg.d/whonix.gpg add ~/patrick.asc
    echo "deb https://deb.whonix.org buster main contrib non-free" | sudo tee /etc/apt/sources.list.d/whonix.list
    sudo apt-get update
    sudo apt-get install monero-gui
}

function trezorBridge {
    https://wallet.trezor.io/#/bridge
}
