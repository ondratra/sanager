set -e

# install necessities
DEBIAN_FRONTEND="noninteractive" apt-get install openssh-server parted -y -qq

# setup ssh
sed -i -r "s~#PermitRootLogin [-a-z]+~PermitRootLogin yes~g" /etc/ssh/sshd_config
sed -i -r "s~#PasswordAuthentication yes~PasswordAuthentication yes~g" /etc/ssh/sshd_config
ssh-keygen -A # ensure mandatory ssh server folders and files exist
systemctl restart sshd

# setup disk /dev/vdb (partman-auto is unable to setup multiple disks)
parted /dev/vdb mklabel gpt
parted -a opt /dev/vdb mkpart primary ext4 0% 100%
mkfs.ext4 /dev/vdb1
mkdir -p /mnt/data
echo '/dev/vdb1 /mnt/data ext4 defaults 0 2' >> /etc/fstab
