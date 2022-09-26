
# TODO: finish this function - it will likely require local Debian mirror (600GB for amd64 repos)
function createCustomInstallIso {
    # see https://salsa.debian.org/images-team/debian-cd/README to get idea what's happening in this function

    exit 123

    # mount Debian mirror FTP to local disk
    if [ -d $LOCAL_DEBIAN_MIRROR ]; then
        # ensure Debian mirror folder is unmounted
        umount -l $LOCAL_DEBIAN_MIRROR
    else
        mkdir -p $LOCAL_DEBIAN_MIRROR
        ls -al $TEST_DIR
    fi
echo $UID
    echo curlftpfs -o uid=$UID,allow_other $DEBIAN_MIRROR_FTP $LOCAL_DEBIAN_MIRROR
    curlftpfs -o uid=$UID $DEBIAN_MIRROR_FTP $LOCAL_DEBIAN_MIRROR

    echo $LOCAL_DEBIAN_MIRROR


    # checkout repository
    if [[ ! -d "$TEST_DIR/debian-cd" ]]; then
      git clone https://salsa.debian.org/images-team/debian-cd.git "$TEST_DIR/debian-cd"
    fi

    cd "$TEST_DIR/debian-cd"

    # download the current version
    git pull origin master

    # change default settings
    sed -i -r "s#DEBVERSION=\"[0-9.]+\"#DEBVERSION=\"$DEBIAN_VERSION\"#g" CONF.sh
    sed -i -r "s#CODENAME=[a-z]+#CODENAME=$NOWADAYS_DEBIAN_VERSION#g" CONF.sh

    sed -i -r "s#MIRROR=.+#MIRROR=$LOCAL_DEBIAN_MIRROR#g" CONF.sh
    sed -i -r "s#TDIR=.+#TDIR=$TEST_DIR/custom_install_medium/tmp#g" CONF.sh
    sed -i -r "s#OUT=.+#OUT=$TEST_DIR/custom_install_medium/out#g" CONF.sh
    sed -i -r "s#APTTMP=.+#APTTMP=$TEST_DIR/custom_install_medium/apt#g" CONF.sh

    sed -i -r "s#CONTRIB=1#CONTRIB=0#g" CONF.sh
    sed -i -r "s#DISKTYPE=CD#DISKTYPE=NETINST#g" CONF.sh

    # include debian-cd settings
    source CONF.sh
echo make distclean
    # make sure working directory is empty
    make distclean
echo make status
    # initialize directory
    make status
echo make packagelists
    # setup packages
    make packagelists TASK=Debian-edu-netinst COMPLETE=0
echo make image-trees
    # create package trees
    make image-trees
echo make images
    # generate installation images
    make images

    # generate checksums
    make imagesums
}
