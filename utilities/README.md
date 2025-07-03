# Useful commands

## Misc
See used ports
```sh
netstat -tulpn
```

Strip image metadata
```sh
mogrify -strip ./*.jpg
```

Generate SSH key
```sh
ssh-keygen -t rsa -b 4096 -f myKey
```

See battery info
```sh
upower -i /org/freedesktop/UPower/devices/battery_BAT0
```

Read and set mac address (spoof) - works until restart
```sh
# read max
cat /sys/class/net/enpXsY/address # replace X and Y
# read mac of WiFi
cat /sys/class/net/wlpXsY/address # replace X and Y

# set custom mac
ip link set enpXsY address 00:11:22:33:44:55  # replace X and Y and mac
```

## Package management

Get package that installed the inspected file/command
```sh
dpkg -S /usr/bin/vim
```

Mark package as manually installed:
```sh
sudo apt-mark manual my-package-name
```
or mark it as automatically installed (may remove package if no other package depends on it)
```sh
sudo apt-mark auto my-package-name
```

See what packages depend on selected package
```sh
apt-cache rdepends my-package-name
```

List *non-free* packages and packages that rely on *non-free* packages (aka *contrib*)
```sh
aptitude search '~i ?section(non-free)
aptitude search '~i ?section(contrib)
```

## Disks

Basic analysis and management
```sh
sudo gparted
# alternatively
sudo gnome-disks
```

Copy whole disk including partitions into a new one
```sh
sudo dd if=/dev/sdXXX of=/dev/sdYYY bs=64K conv=noerror,sync status=progress
```

Copy only individual partitions
```sh
sudo dd if=/dev/sdXXX1 of=/dev/sdYYY1 bs=64K conv=noerror,sync status=progress
# resize partition to match the size of partition on the new disk
sudo resize2fs /dev/sdYYY1
```
Consider generating a new UUID for a partition(s) afterwards. Otherwise you mind end up with multiple partitions
with the same UUID that will cause problems. Don't forget to update `/etc/fstab` afterwards.

### EFI

EFI partition setup
- FAT32 partition with flags `GPT + BOOT`
- use at least 256 MB, preferably 1 GB
    - otherwise you will not be able to resize the partition (limitation of `libparted`)

EFI partition reinstall
- https://wiki.debian.org/GrubEFIReinstall

### CLI alternatives to `gparted` and `gnome-disks`
```sh
# fix problems with filesystem
fsck /dev/sdb1

# generate new UUID for partition (NNN is partition index)
sudo sgdisk --partition-guid=NNN:new /dev/sdX
```

## Create Debian bootable CD/USB
```sh
cp debian.iso /dev/sdXXX
sync
```

### ZFS
Sources:
- https://wiki.debian.org/ZFS

Get partition's UUID (works even in some cases when `ls -al /dev/disk/by-uuid/` has missing results):
```sh
sudo blkid /dev/sdX1
```

Create 2 disks mirror pool:
```sh
MY_ZFS_POOL_NAME=myPool

sudo zpool create $MY_ZFS_POOL_NAME mirror \
    /dev/disk/by-partuuid/09f2ecb6-7802-4fcd-9a95-fb828f0781be \
    /dev/disk/by-partuuid/1312069d-7b9e-41e5-8490-5ec788d141c4

# check status
zpool status
```

Set mount point for a pool:
```sh
sudo zfs set mountpoint=/desired/mount/point $MY_ZFS_POOL_NAME
```

See existing mounting points:
```sh
zfs get mountpoint
```

Create 1 disk backup pool:
```sh
MY_ZFS_BACKUP_POOL_NAME=myBackupPool

sudo zpool create $MY_ZFS_BACKUP_POOL_NAME
sudo zpool set compression=lz4 $MY_ZFS_BACKUP_POOL_NAME
```

Creating backup
```sh
PC_NAME=myPc
SNAPSHOT_NAME=initial # CHANGE THIS EACH TIME!

# create at-the-moment snapshot
sudo zfs snapshot -r ${MY_ZFS_POOL_NAME}@${SNAPSHOT_NAME}

# ensure parent structure exist in backup pool
sudo zfs list "$MY_ZFS_BACKUP_POOL_NAME" >/dev/null 2>&1 || sudo zfs create -p "$MY_ZFS_BACKUP_POOL_NAME"

# send snapshot to backup pool (no progress shown)
sudo zfs send -v ${MY_ZFS_POOL_NAME}@${SNAPSHOT_NAME} | sudo zfs receive $MY_ZFS_BACKUP_POOL_NAME/Backups/$PC_NAME/$MY_ZFS_POOL_NAME
```

#### Single disk ZFS pool
```sh
# show status
lsblk -f

# create single partition on disk
sudo parted /dev/sdX -- mklabel gpt
sudo parted -a optimal /dev/sdX -- mkpart primary 0% 100% # uses 100% of disk!

# generate UUID for partition
blkid /dev/sdX1

# create pool - mind the difference between capital `-O` and lowercase `-o`
sudo zpool create \
  -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  my-pool-name \
  /dev/disk/by-partuuid/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

#### Automatic backups using Sanoid & Syncoid

Sanager installs Sanoid and Syncoid via low level install `zfsLuks`. After the install you need to setup your backup
strategy for the specific machine:
- edit `/etc/sanoid/sanoid.conf` - create record for each dataset you want to backup
- edit `/etc/systemd/system/syncoid.service` - edit `ExecStart` value so it uses your proper datasets
- `systemctl enable sanoid --now` - ensure Sanoid is running
- reload Syncoid config
    ```sh
    systemctl daemon-reload
    systemctl enable --now syncoid.timer
    ```
