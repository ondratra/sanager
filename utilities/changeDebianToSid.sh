# TODO: create both-way switch for sid/stable if it's ever needed (
#       possible reasons might be:
#       1) to fix mistakenly activated sid
#       2) to get default values
#       3) update to newest stable release

# careful with this one -> it might change your `stable` system into `unstable`/`sid` if you're not using it yet
function useUnstableRepositories {
    local APT_SOURCES_PATH=/etc/apt/sources.list

    deb_line=$(grep -E '^deb\s+' /etc/apt/sources.list | head -n1)

    options=$(echo "$deb_line" | sed -nE 's|^deb\s+(\[[^]]+\])\s+.*|\1|p')
    mirror=$(echo "$deb_line" | sed -E 's|^deb\s+(\[[^]]+\]\s+)?(https?://[^ ]+).*|\2|')
    components=$(echo "$deb_line" | sed -E 's|^deb\s+(\[[^]]+\]\s+)?(https?://[^ ]+)\s+[a-z-]+\s+(.*)|\3|')

    local DEB_LINE="deb $options $mirror unstable $components"
    local DEB_SRC_LINE="deb-src $options $mirror unstable $components"

    echo -e "$DEB_LINE\n$DEB_SRC_LINE" > $APT_SOURCES_PATH
}

useUnstableRepositories
