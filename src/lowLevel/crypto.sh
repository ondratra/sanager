
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
