function dumpMateConfiguration {
    local CONFIG_FILE_PATH="$1"

    dconf dump /org/mate/ > $CONFIG_FILE_PATH
}

# splits ini file into multiple files each containing one section of input file
function splitIniFile {
    local INI_FILE_PATH="$1"

    local PARTS_DIR="$SCRIPT_DIR/data/mate/parts"

    # remove all old parts
    rm -rf $PARTS_DIR/*

    local SECTION=__default

    # read input file
    while IFS= read -r line; do
        # check if line starts with section declaration
        if [[ $line == [* ]]; then
            SECTION=$(echo "$line" | sed 's/\[//;s/\]//')

            # create directory for this part
            local THIS_PART_DIR="`dirname \"$PARTS_DIR/$SECTION\"`"
            mkdir -p "$THIS_PART_DIR"

            echo "$line" > "$PARTS_DIR/$SECTION.txt"
        elif [[ ! -z $line ]]; then
            echo "$line" >> "$PARTS_DIR/$SECTION.txt"
        fi
    done < $INI_FILE_PATH
}

function fillConfigVariables {
    local CONFIG_FILE_PATH=$1

    sed \
        -i \
        -e "s|$(xdg-user-dir PICTURES)|__\$XDG_PICTURES_DIR__|g" \
        -e "s|$(xdg-user-dir DOWNLOAD)|__\$XDG_DOWNLOAD_DIR__|g" \
        -e "s|$HOME|__\$HOME__|g" \
        $CONFIG_FILE_PATH
}

function exportMateConfig {
    local CONFIG_FILE_PATH="$SANAGER_INSTALL_TEMP_DIR/sanagerMateConfig.txt"

    dumpMateConfiguration $CONFIG_FILE_PATH
    fillConfigVariables $CONFIG_FILE_PATH
    splitIniFile $CONFIG_FILE_PATH

    cp ~/.config/mimeapps.list $SCRIPT_DIR/data/misc/

    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" "$SCRIPT_DIR/data/mate"
}
