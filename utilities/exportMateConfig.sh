#!/bin/bash

# escape on error
set -e

SCRIPT_DIR="`dirname \"$0\"`" # relative
SCRIPT_DIR="`( cd \"$SCRIPT_DIR\" && pwd )`"  # absolutized and normalized

function exportMateConfiguration {
    local CONFIG_FILE_PATH="$1"

    dconf dump /org/mate/ > $CONFIG_FILE_PATH
}

# splits ini file into multiple files each containing one section of input file
function splitIniFile {
    local INI_FILE_PATH="$1"

    local INI_FILE_DIR="`dirname \"$INI_FILE_PATH\"`"

    local PARTS_DIR="$INI_FILE_DIR/parts"

    # remove all old parts
    rm -rf "$PARTS_DIR/*"

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

function main {
    local CONFIG_FILE_PATH="$SCRIPT_DIR/../data/mate/config.txt"

    exportMateConfiguration $CONFIG_FILE_PATH
    splitIniFile $CONFIG_FILE_PATH
}

main
