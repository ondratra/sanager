# Useful commands
WIP

## Misc
See used ports
```
netstat -tulpn
```

Strip image metadata
```
mogrify -strip ./*.jpg
```

Generate SSH key
```
ssh-keygen -t rsa -b 4096 -f myKey
```

See battery info
```
upower -i /org/freedesktop/UPower/devices/battery_BAT0
```

## Package management

Get package that installed the inspected file/command
```
dpkg -S /usr/bin/vim
```

Mark package as manually installed:
```
sudo apt-mark manual my-package-name
```
or mark it as automatically installed (may remove package if no other package depends on it)
```
sudo apt-mark auto my-package-name
```

See what packages depend on selected package
```
apt-cache rdepends my-package-name
```

List *non-free* packages and packages that rely on *non-free* packages (aka *contrib*)
```
aptitude search '~i ?section(non-free)
aptitude search '~i ?section(contrib)
```

## Disks

Basic analysis and management
```
sudo gparted
# alternatively
sudo gnome-disks
```

Copy whole disk including partitions into a new one
```
sudo dd if=/dev/sdXXX of=/dev/sdYYY bs=64K conv=noerror,sync status=progress
```

Copy only individual partitions
```
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
```
# fix problems with filesystem
fsck /dev/sdb1

# generate new UUID for partition (NNN is partition index)
sudo sgdisk --partition-guid=NNN:new /dev/sdX
```

## Create Debian bootable CD/USB
```
cp debian.iso /dev/sdXXX
sync
```

### ZFS
Sources:
- https://wiki.debian.org/ZFS

Get partition's UUID (works even in some cases when `ls -al /dev/disk/by-uuid/` has missing results):
```
sudo blkid /dev/sdX1
```

Create 2 disks mirror pool:
```
MY_ZFS_POOL_NAME=myPool

sudo zpool create $MY_ZFS_POOL_NAME mirror \
    /dev/disk/by-partuuid/09f2ecb6-7802-4fcd-9a95-fb828f0781be \
    /dev/disk/by-partuuid/1312069d-7b9e-41e5-8490-5ec788d141c4

# check status
zpool status
```

Set mount point for a pool:
```
sudo zfs set mountpoint=/desired/mount/point $MY_ZFS_POOL_NAME
```

See existing mounting points:
```
zfs get mountpoint
```

Create 1 disk backup pool:
```
MY_ZFS_BACKUP_POOL_NAME=myBackupPool

sudo zpool create $MY_ZFS_BACKUP_POOL_NAME
sudo zpool set compression=lz4 $MY_ZFS_BACKUP_POOL_NAME
```

Creating backup
```
PC_NAME=myPc
SNAPSHOT_NAME=initial # CHANGE THIS EACH TIME!

# create at-the-moment snapshot
sudo zfs snapshot -r ${MY_ZFS_POOL_NAME}@${SNAPSHOT_NAME}

# ensure parent structure exist in backup pool
sudo zfs list "$MY_ZFS_BACKUP_POOL_NAME" >/dev/null 2>&1 || sudo zfs create -p "$MY_ZFS_BACKUP_POOL_NAME"

# send snapshot to backup pool (no progress shown)
sudo zfs send -v ${MY_ZFS_POOL_NAME}@${SNAPSHOT_NAME} | sudo zfs receive $MY_ZFS_BACKUP_POOL_NAME/Backups/$PC_NAME/$MY_ZFS_POOL_NAME
```