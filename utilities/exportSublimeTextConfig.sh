function exportSublimeTextConfig {
    cp ~/.config/sublime-text/Packages/$SUBLIME_TEXT_PACKAGE_LOCAL_NAME $SCRIPT_DIR/data/sublimeText -rT

    sed -i 's|^\( *\)\("theme":\)|\1//\2|' "$SCRIPT_DIR/data/sublimeText/Preferences.sublime-settings.symlinktarget"
}
