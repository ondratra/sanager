function systeminfo {
    local HOSTNAME_VAL=$(hostname)
    local KERNEL=$(uname -r)
    local DISK_DEV=$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1; exit}')
    local OS_DESC=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    local DATE_VAL=$(date '+%Y-%m-%d %H:%M:%S')

    echo "Date: $DATE_VAL"
    echo "Host: $HOSTNAME_VAL"
    echo "OS: $OS_DESC"
    echo "Kernel: $KERNEL"

    sectionMemory
    sectionCpu
    sectionGpus
}

function sectionCpu {
    echo "CPU(s)"

    local SOCKET_IDS=$(awk -F: '/^physical id/{print $2+0}' /proc/cpuinfo | sort -un)

    if [[ -z "$SOCKET_IDS" ]]; then
        SOCKET_IDS="0"
    fi

    local SOCKET_COUNT=$(echo "$SOCKET_IDS" | wc -w)
    echo "  Sockets count:" "$SOCKET_COUNT"

    for SOCKET_ID in $SOCKET_IDS; do
        local BLOCK=$(awk -v sid="$SOCKET_ID" '
            /^$/ {
                if (found) { print buf; print "" }
                buf=""; found=0; next
            }
            /^physical id/ {
                split($0, a, /:[[:space:]]*/); if (a[2]+0 == sid+0) found=1
            }
            { buf = buf $0 "\n" }
            END { if (found) print buf }
        ' /proc/cpuinfo)

        # fallback for virtual sockets
        [[ -z "$BLOCK" ]] && BLOCK=$(cat /proc/cpuinfo)

        local MODEL=$(echo "$BLOCK" | awk -F'\t: ' '/^model name/{print $2; exit}')
        local CORES=$(echo "$BLOCK" | awk -F: '/^cpu cores/{print $2+0; exit}')
        local THREADS=$(echo "$BLOCK" | awk -F: '/^siblings/{print $2+0; exit}')

        local FREQ_FILE="/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"
        if [[ -r "$FREQ_FILE" ]]; then
            MAX_FREQ=$(awk '{printf "%.0f MHz", $1/1000}' "$FREQ_FILE")
        else
            MAX_FREQ=$(awk -F: '/^cpu MHz/{sum+=$2; n++} END{if(n) printf "~%.0f MHz (current avg)", sum/n}' /proc/cpuinfo)
        fi

        echo "  Socket #${SOCKET_ID}:"
        echo "    Model:"  "${MODEL:-unknown}"
        echo "    Cores:"  "${CORES:-?} physical / ${THREADS:-?} logical"
        echo "    Freq:"   "$MAX_FREQ"
    done
}

function sectionMemory {
    local MEMORY_TOTAL=$(awk '/MemTotal/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo)
    local ECC=""

    if command -v dmidecode &>/dev/null; then
        ECC=$(dmidecode -t memory 2>/dev/null | awk '/Error Correction Type:/{
                if ($0 ~ /None|Unknown/) ecc=""
                else ecc="ECC"
            } END{print ecc}'
        )
    fi

    echo "RAM: $MEMORY_TOTAL${ECC:+ $ECC}"

    ramSticksInfo | sed 's/^/    /'
}

function sectionGpus {
    echo "GPU(s)"

    local GPU_FOUND=0

    # nvidia
    if command -v nvidia-smi &>/dev/null; then
        while IFS=',' read -r IDX GPU_NAME MEM_TOTAL_MB; do
            local IDX=$(echo "$IDX" | xargs)
            local GPU_NAME=$(echo "$GPU_NAME" | xargs)
            local MEM_GIB=$(awk "BEGIN{printf \"%.1f GiB\", $MEM_TOTAL_MB/1024}")
            echo "  NVIDIA $IDX:" "$GPU_NAME | VRAM: $MEM_GIB"
            GPU_FOUND=1
        done < <(nvidia-smi \
            --query-gpu=index,name,memory.total \
            --format=csv,noheader 2>/dev/null)
    fi

    # amd
    for CARD in /sys/class/drm/card*/device; do
        [[ "$(cat "$CARD/vendor" 2>/dev/null)" != "0x1002" ]] && continue

        local CARD_NAME=$(basename "$(dirname "$CARD")")
        local PCI_SLOT=$(cat "$CARD/uevent" 2>/dev/null | awk -F= '/PCI_SLOT_NAME/{print $2}')
        local AMD_MODEL=$(lspci -vmm -s "$PCI_SLOT" 2>/dev/null | awk -F'\t' '/^Device:/{print $2; exit}')

        local VRAM_BYTES=$(cat "$CARD/mem_info_vram_total" 2>/dev/null || echo "")
        if [[ -n "$VRAM_BYTES" && "$VRAM_BYTES" -gt 0 ]]; then
            VRAM=$(awk "BEGIN{printf \"%.1f GiB\", $VRAM_BYTES/1024/1024/1024}")
        else
            VRAM="unknown"
        fi

        echo "  AMD $CARD_NAME:" "$AMD_MODEL | VRAM: $VRAM"
        GPU_FOUND=1
    done

    # intel integrated
    for CARD in /sys/class/drm/card*/device; do
        [[ "$(cat "$CARD/vendor" 2>/dev/null)" != "0x8086" ]] && continue

        local CLASS_ID=$(cat "$CARD/class" 2>/dev/null || echo "")
        echo "$CLASS_ID" | grep -qE "0x0300|0x0380" || continue

        local CARD_NAME=$(basename "$(dirname "$CARD")")
        local INTEL_MODEL=$(cat "$CARD/product_name" 2>/dev/null || echo "Intel Integrated Graphics")

        echo "  Intel integrated $CARD_NAME:" "$INTEL_MODEL | VRAM: shared"
        GPU_FOUND=1
    done

    # fallback for other gpus
    if [[ $GPU_FOUND -eq 0 ]] && command -v lspci &>/dev/null; then
        while IFS= read -r GPU_LINE; do
            echo "  GPU (lspci):" "$GPU_LINE"
            GPU_FOUND=1
        done < <(lspci 2>/dev/null | grep -E 'VGA|3D|Display' || true)
    fi

    if [[ $GPU_FOUND -ne 0 ]]; then
        echo "GPU:" "none detected"
    fi
}

function ramSticksInfo {
    sudo dmidecode -t memory | awk '
        BEGIN {
            total_mb = 0
            stick_index = 0
        }

        /^Memory Device$/ {
            size=""; type=""; speed=""; conf_speed=""; ecc="";

            stick_index++;

            print "Stick #" stick_index
            next
        }

        /^[[:space:]]*Size:/ {
            if ($2 == "No" || $2 == "None") next
            size = $2 " " $3

            if ($3 == "GB") total_mb += $2 * 1024
            else if ($3 == "MB") total_mb += $2

            print "    Size: " size
        }

        /^[[:space:]]*Type:/ {
            if ($2 != "Unknown")
              print "    DDR type: " $2
        }

        /^[[:space:]]*Speed:/ {
            if ($2 ~ /^[0-9]+$/ && $3 == "MT/s")
              print "    Max speed: " $2 " " $3
        }

        /^[[:space:]]*Configured Memory Speed:/ {
            if ($4 ~ /^[0-9]+$/ && $5 == "MT/s") {
                conf_speed = $4 " " $5
                print "    Configured speed: " conf_speed
            }
        }

        END {
            if (total_mb > 0)
                printf "Total Memory: %.1f GB\n", total_mb / 1024

            if (conf_speed)
                print "Configured speed: " conf_speed
        }
    '
}
