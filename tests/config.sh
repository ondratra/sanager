SANAGER_MAIN_DIR=`realpath $(dirname $SCRIPT_DIR)`

# config
DEBIAN_VERSION="11.4.0"
NOWADAYS_DEBIAN_VERSION="bullseye"
#DEBIAN_MIRROR_FTP="ftp.cz.debian.org/debian/"
DEBIAN_MIRROR_FTP="ftp.us.debian.org/debian/"

VM_USERS_ROOT_NAME=root
VM_USERS_ROOT_PASSWORD=root
VM_USERS_SANAGER_NAME=sanager
VM_USERS_SANAGER_PASSWORD=sanager

NETINSTALL_ISO_FILENAME="debian-$DEBIAN_VERSION-amd64-netinst.iso"
TEST_DIR="$SANAGER_MAIN_DIR/.sanagerTests"
VIRTUAL_MACHINES_DIR="$TEST_DIR/virtualMachines"
NETINSTALL_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/$NETINSTALL_ISO_FILENAME"
NETINSTALL_ISO_FILE="$TEST_DIR/$NETINSTALL_ISO_FILENAME"
LOCAL_DEBIAN_MIRROR="$TEST_DIR/DebianMirror"
SANAGER_GUEST_FOLDER_NAME=sanager
SANAGER_GUEST_FOLDER_PATH=/home/$VM_USERS_SANAGER_NAME/$SANAGER_GUEST_FOLDER_NAME

MACHINE_NAME_TEMPORARY="Sanager_Temporary"
MACHINE_NAME_BARE="Sanager_Testing_Bare"
MACHINE_NAME_WITH_OS="Sanager_Testing_WithOS"
MACHINE_NAME_WITH_OS_AND_GUEST_ADDITIONS="Sanager_Testing_WithOS_GuestAdditions"
MACHINE_NAME_TEST_PREFIX="Sanager_Testing_Runner_"

SSH_TUNNEL_HOST_PORT=2222
SSH_TUNNEL_HOST_HOSTNAME=127.0.0.1
SSH_TUNNEL_GUEST_PORT=22