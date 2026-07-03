#!/bin/bash

# interrupt on error
set -e
#set -eu # TODO: use this to catch undefined variables
set -x # uncomment when debugging

SCRIPT_DIR="`dirname \"$0\"`" # relative
LAN_BRIDGE_NAME="bridge-vm-lan"

source "$SCRIPT_DIR/../config.sh"
source "$SCRIPT_DIR/../misc/utils.sh"

if [[ $# -ne 1 ]]; then
    echo "Connect VMs to physical LAN via already existing bridge"
    echo "Usage:",
    echo "$0 VM_NAME_1"

    exit 1
fi

function ensureBridgeExists {
    if ip link show "$LAN_BRIDGE_NAME" >/dev/null 2>&1; then
        return
    fi

    echo "Bridge network interface is missing."
    echo "You can adjust the following template and put it into /etc/network/interfaces.d/$LAN_BRIDGE_NAME"

    cat <<EOF
auto eno1 # use physical interface name - e.g. eno1 or enp5s0
iface eno1 inet manual

auto $LAN_BRIDGE_NAME
iface $LAN_BRIDGE_NAME inet static
    address xxx.xxx.xxx.xxx/yy # address of bridging interface
    bridge_ports eno1
    bridge_stp off
EOF

    exit 1
}

ensureBridgeExists

VM_NAME="$1"
MAC_ADDRESS=`generateMacForVm "$VM_NAME" "$LAN_BRIDGE_NAME"`

virsh attach-interface "$VM_NAME" \
    --type bridge \
    --source "$LAN_BRIDGE_NAME" \
    --model virtio \
    --mac "$MAC_ADDRESS" \
    --config

echo "VM connected to lan"
