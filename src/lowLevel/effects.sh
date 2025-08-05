#!/bin/bash

# enables bash history search by PageUp and PageDown keys
function enableHistorySearch {
    # works system wide (changing /etc/inputrc)
    sed -e '/.*\(history-search-backward\|history-search-forward\)/s/^# //g' /etc/inputrc > tmpSedReplacementFile && mv tmpSedReplacementFile /etc/inputrc
}

function enableBashCompletion {
    applyPatch /etc/bash.bashrc < $SCRIPT_DIR/data/misc/bash.bashrc.diff || true
}

function restoreMateConfig {
    function downloadTheme {
        THEME_URL="https://codeload.github.com/rtlewis88/rtl88-Themes/zip/refs/heads/Arc-Darkest-Nord-Frost"
        THEME_INTER_FOLDER="rtl88-Themes-Arc-Darkest-Nord-Frost"
        THEME_SUBFOLDER="Arc-Darkest-Nord-Frost"
        THEME_OUTPUT_FILE="$THEME_INTER_FOLDER.zip"

        if [ -d ~/.themes/$THEME_SUBFOLDER ]; then
            return
        fi

        # extract theme in temporary folder
        mkdir -p tmp/theme
        cd tmp
        wgetDownload "$THEME_URL" -O "$THEME_OUTPUT_FILE"
        7z x "$THEME_OUTPUT_FILE" -o"./theme" # intentionally no space after `-o`

        mkdir -p ~/.themes # ensure themes folder exist -> only important before first login into graphical interface
        cp -rf "./theme/$THEME_INTER_FOLDER/$THEME_SUBFOLDER" ~/.themes/$THEME_SUBFOLDER
        chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" ~/.themes

        # clean tmp folder
        cd ..
        rm tmp -r
    }

    function recomposeConfig {
        local PARTS_DIR="$1"
        local OUTPUT_FILE="$2"

        local FILE_PATHS=`find "$PARTS_DIR" -type f -name "*.txt" | sed -e "s/\.txt$//" | sort | sed -e "s/$/.txt/"`

        echo -n "" > $OUTPUT_FILE
        local FIRST_LINE="1"
        for FILE in $FILE_PATHS; do
            if [[ $FIRST_LINE == "1" ]]; then
                FIRST_LINE="0"
            else
                echo >> $OUTPUT_FILE
            fi

            cat "${FILE}" >> $OUTPUT_FILE
        done
    }

    function setUiScale {
        local RESOLUTION=$(xrandr | grep '*' | awk '{print $1}')

        local WIDTH=${RESOLUTION%x*}
        local SCALE=1

        if [ "$WIDTH" -gt 1920 ]; then
            SCALE=2
        fi

        # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
        sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS  gsettings set org.mate.interface window-scaling-factor "$SCALE"
    }

    local OUTPUT_FILE="$SCRIPT_DIR/data/mate/config.txt"
    local PARTS_DIR="$SCRIPT_DIR/data/mate/parts"

    recomposeConfig $PARTS_DIR $OUTPUT_FILE
    chown "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $OUTPUT_FILE

    downloadTheme

    # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
    sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS dconf load /org/mate/ < "$SCRIPT_DIR/data/mate/config.txt"
    setUiScale

    cp -f $SCRIPT_DIR/data/misc/mimeapps.list ~/.config/ # restore "Open with" settings
    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" ~/.config/mimeapps.list
}

function installSanagerGlobally {
    EXECUTABLE_PATH=/usr/bin/sanager

    rm -rf $EXECUTABLE_PATH
    ln -s "$SCRIPT_DIR/systemInstall.sh" $EXECUTABLE_PATH
}

function installSanagerMedia {
    MEDIA_TEMPLATES_DIR=$SCRIPT_DIR/data/sanager/mediaTemplatesSources
    MEDIA_TEMP_DIR=$SANAGER_INSTALL_TEMP_DIR/mediaTemplates

    mkdir -p $MEDIA_TEMP_DIR

    for svgFile in $MEDIA_TEMPLATES_DIR/*.svg; do
        targetFilename="${svgFile##*/}"         # strip path
        targetFilename="${targetFilename%.svg}"   # strip .svg extension

        convert "$svgFile" -background white -flatten "$MEDIA_TEMP_DIR/$targetFilename"
    done

    cp -rn $MEDIA_TEMP_DIR/. $SANAGER_MEDIA_DIR/ #doesn't overwrite existing - possibly modified - files
    rm -r $MEDIA_TEMP_DIR
}

function setupTempSensors {
    sensors-detect --auto
}
