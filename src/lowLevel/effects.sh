#!/bin/bash

# enables bash history search by PageUp and PageDown keys
function effect_enableHistorySearch {
    # works system wide (changing /etc/inputrc)
    sed -e '/.*\(history-search-backward\|history-search-forward\)/s/^# //g' /etc/inputrc > tmpSedReplacementFile && mv tmpSedReplacementFile /etc/inputrc
}

function effect_enableBashCompletion {
    applyPatch /etc/bash.bashrc < $SCRIPT_DIR/data/misc/bash.bashrc.diff || true
}

function effect_restoreMateConfig {
    function downloadTheme {
        local THEME_URL="https://codeload.github.com/rtlewis88/rtl88-Themes/zip/refs/heads/Arc-Darkest-Nord-Frost"
        local THEME_INTER_FOLDER="rtl88-Themes-Arc-Darkest-Nord-Frost"
        local THEME_SUBFOLDER="Arc-Darkest-Nord-Frost"
        local THEME_OUTPUT_FILE="$THEME_INTER_FOLDER.zip"

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
                local FIRST_LINE="0"
            else
                echo >> $OUTPUT_FILE
            fi

            cat "${FILE}" >> $OUTPUT_FILE
        done
    }

    function fillConfigVariables {
        local CONFIG_FILE=$1

        sed \
            -i \
            -e "s|__\$HOME__|$HOME|g" \
            -e "s|__\$XDG_PICTURES_DIR__|$(xdg-user-dir PICTURES)|g" \
            -e "s|__\$XDG_DOWNLOAD_DIR__|$(xdg-user-dir DOWNLOAD)|g" \
            $CONFIG_FILE
    }

    function setUiScale {
        local RESOLUTION=$(xrandr | grep '*' | awk '{print $1}')

        local WIDTH=${RESOLUTION%x*}
        local SCALE=1

        if [ "$WIDTH" -gt 1920 ]; then
            local SCALE=2
        fi

        # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
        sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS  gsettings set org.mate.interface window-scaling-factor "$SCALE"
    }

    local OUTPUT_FILE="$SCRIPT_DIR/data/mate/config.txt"
    local PARTS_DIR="$SCRIPT_DIR/data/mate/parts"

    recomposeConfig $PARTS_DIR $OUTPUT_FILE
    fillConfigVariables $OUTPUT_FILE
    chown "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" $OUTPUT_FILE

    downloadTheme

    # passing DBUS_SESSION_BUS_ADDRESS might seem meaningless but it is needed to make dconf work with sudo
    sudo -u $SCRIPT_EXECUTING_USER DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS dconf load /org/mate/ < "$OUTPUT_FILE"
    setUiScale

    cp -f $SCRIPT_DIR/data/misc/mimeapps.list ~/.config/ # restore "Open with" settings
    chown -R "$SCRIPT_EXECUTING_USER:$SCRIPT_EXECUTING_USER" ~/.config/mimeapps.list
}

function effect_installSanagerGlobally {
    local EXECUTABLE_PATH=/usr/bin/sanager

    rm -rf $EXECUTABLE_PATH
    ln -s "$SCRIPT_DIR/systemInstall.sh" $EXECUTABLE_PATH
}

function effect_installSanagerMedia {
    local MEDIA_TEMPLATES_DIR=$SCRIPT_DIR/data/sanager/mediaTemplatesSources
    local MEDIA_TEMP_DIR=$SANAGER_INSTALL_TEMP_DIR/mediaTemplates

    mkdir -p $MEDIA_TEMP_DIR

    for svgFile in $MEDIA_TEMPLATES_DIR/*.svg; do
        local targetFilename="${svgFile##*/}"         # strip path
        local targetFilename="${targetFilename%.svg}"   # strip .svg extension

        convert "$svgFile" -background white -flatten "$MEDIA_TEMP_DIR/$targetFilename"
    done

    cp -rn $MEDIA_TEMP_DIR/. $SANAGER_MEDIA_DIR/ #doesn't overwrite existing - possibly modified - files
    rm -r $MEDIA_TEMP_DIR
}

function effect_setupTempSensors {
    sensors-detect --auto
}

function effect_changeMysqlPassword {
    local NEW_PASSWORD="$1"
    echo "newPassword: '$1'"
    local TMP_FILE="$SANAGER_INSTALL_DIR/tmp.sql"
    local SQL_QUERY="FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$NEW_PASSWORD'; FLUSH PRIVILEGES; SHUTDOWN;";

    systemctl stop mysql > /dev/null 2> /dev/null

    mkdir -p /var/run/mysqld
    chown mysql:mysql /var/run/mysqld
    mysqld_safe --skip-grant-tables &
    # make sure query is accpeted by server(aka server is running)
    local TMP="1"
    while [[ "$TMP" != "0" ]]; do
        printMsg "waiting for MySQL server"
        (mysql <<< $SQL_QUERY && TMP="0") || TMP="1"
        sleep 1
    done
    systemctl start mysql

    # fix tables after dirty MySQL import (copying /var/lib/mysql folder instead of using `mysqldump`)
    # mysqlcheck -u [username] -p --all-databases --check-upgrade --auto-repair
}

function effect_distUpgrade {
    aptUpdate
    aptDistUpgrade
}

function effect_distCleanup {
    aptFixDependencies
    aptCleanup
}

function effect_setupShellPrompt {
    local PS1_LINE='export PS1="\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ "'

    grep -qxF "$PS1_LINE" ~/.bashrc || echo "$PS1_LINE" >> ~/.bashrc
}
