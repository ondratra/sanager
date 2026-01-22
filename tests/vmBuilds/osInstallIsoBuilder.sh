function createCustomInstallIso {
    if [[ -f "$NETINSTALL_FINAL_ISO_FILE" ]]; then
        return 0
    fi

    local ISO_MOUNT_PATH="$NETINSTALL_ISO_BUILD_DIR/isoMount"
    local ISO_WORKDIR_PATH="$NETINSTALL_ISO_BUILD_DIR/isoContent"

    # ensure working directories
    mkdir -p "$ISO_MOUNT_PATH" "$ISO_WORKDIR_PATH"

    # download Debian install iso
    downloadInstallMedium

    # create working directory
    fuseiso "$NETINSTALL_ORIGINAL_ISO_FILE" "$ISO_MOUNT_PATH"
    rsync -a "$ISO_MOUNT_PATH/" "$ISO_WORKDIR_PATH/"
    sync && sleep 0.1 # prevents problem with umounting
    fusermount -u "$ISO_MOUNT_PATH"
    chmod -R u+rwx "$ISO_WORKDIR_PATH"

    # copy selection preseed into working dir
    cp -rf "$NETINSTALL_EXTRA_DATA_DIR"/* "$ISO_WORKDIR_PATH/"

    local PRESEED="auto=true priority=critical preseed/file=/cdrom/preseed.cfg"

    # force unattended install (BIOS)
    sed -i \
        's|append vga=788 initrd=.*|append vga=788 initrd=/install.amd/initrd.gz '"$PRESEED"' ---|' \
        "$ISO_WORKDIR_PATH/isolinux/txt.cfg"
    sed -i \
        -e 's/^timeout .*/timeout 1/' \
        -e 's/^default .*/default install/' \
        "$ISO_WORKDIR_PATH/isolinux/isolinux.cfg"

    # force unattended install (UEFI)
    sed -zi \
        's|---|'"$PRESEED"' ---|2' \
        "$ISO_WORKDIR_PATH/boot/grub/grub.cfg"
    sed -i \
        "s|menuentry --hotkey=i 'Install' {|set default=\"autoinstall\"\nset timeout=1\nmenuentry --hotkey=i --id autoinstall 'Install' {|" \
        "$ISO_WORKDIR_PATH/boot/grub/grub.cfg"

    updatePreseedWithLocalMachineSettings "$ISO_WORKDIR_PATH/preseed.cfg"

    # build iso (supports both BIOS and UEFI)
    xorriso -as mkisofs \
        -o "$NETINSTALL_FINAL_ISO_FILE" \
        -r -J \
        -V "$NETINSTALL_FINAL_ISO_TITLE" \
        -cache-inodes \
        \
        -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
        \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        \
        "$ISO_WORKDIR_PATH"
}

function updatePreseedWithLocalMachineSettings {
    local PRESEED_FILE="$1"
    function updatePreseedLocale {
        local CURRENT_LOCALE=$(localectl status | grep "LANG=" | cut -d= -f2)
        local CURRENT_LAYOUT=$(localectl status | grep "X11 Layout:" | awk -F: '{print $2}' | xargs)

        sed -i "s|^d-i debian-installer/locale string .*|d-i debian-installer/locale string $CURRENT_LOCALE|" "$PRESEED_FILE"
        sed -i "s|^d-i keyboard-configuration/xkb-keymap select .*|d-i keyboard-configuration/xkb-keymap select $CURRENT_LAYOUT|" "$PRESEED_FILE"

    }

    function updatePreseedAptMirror {
        # Get the mirror URL from sources.list (assuming single deb line)
        local MIRROR_LINE=$(grep "^deb " /etc/apt/sources.list | head -n 1)

        # Extract mirror URL, handling optional [signed-by=...] section
        # If there's a bracket, the URL is in field 3, otherwise field 2
        if echo "$MIRROR_LINE" | grep -q "\["; then
            local MIRROR_URL=$(echo "$MIRROR_LINE" | awk '{print $3}')
        else
            local MIRROR_URL=$(echo "$MIRROR_LINE" | awk '{print $2}')
        fi

        # Extract hostname (remove http:// or https:// and everything after first /)
        local MIRROR_HOSTNAME=$(echo "$MIRROR_URL" | sed 's|^https\?://||' | cut -d'/' -f1)

        # Extract directory (everything after hostname)
        local MIRROR_DIRECTORY=$(echo "$MIRROR_URL" | sed 's|^https\?://[^/]*||')

        sed -i "s|^d-i mirror/http/hostname string .*|d-i mirror/http/hostname string $MIRROR_HOSTNAME|" "$PRESEED_FILE"
        sed -i "s|^d-i mirror/http/directory string .*|d-i mirror/http/directory string $MIRROR_DIRECTORY|" "$PRESEED_FILE"
    }

    function updatePreseedUsers {
        # Update root password (both entries)
        sed -i "s|^d-i passwd/root-password password .*|d-i passwd/root-password password $VM_USERS_ROOT_PASSWORD|" "$PRESEED_FILE"
        sed -i "s|^d-i passwd/root-password-again password .*|d-i passwd/root-password-again password $VM_USERS_ROOT_PASSWORD|" "$PRESEED_FILE"

        # Update username
        sed -i "s|^d-i passwd/username string .*|d-i passwd/username string $VM_USERS_SANAGER_NAME|" "$PRESEED_FILE"

        # Update user password (both entries)
        sed -i "s|^d-i passwd/user-password password .*|d-i passwd/user-password password $VM_USERS_SANAGER_PASSWORD|" "$PRESEED_FILE"
        sed -i "s|^d-i passwd/user-password-again password .*|d-i passwd/user-password-again password $VM_USERS_SANAGER_PASSWORD|" "$PRESEED_FILE"
    }

    function updateTimezone {
        local CURRENT_TIMEZONE=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')

        sed -i "s|^d-i time/zone string .*|d-i time/zone string $CURRENT_TIMEZONE|" "$PRESEED_FILE"
    }

    updatePreseedLocale
    updatePreseedAptMirror
    updatePreseedUsers
    updateTimezone
}
