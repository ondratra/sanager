
# wrapper for lowLevel routines -> enables calling of individual lowLevel routines

function runHighLevel {

    if [[ $# -eq 0 ]]; then
        echo "Invalid parameter count."
        echo "Select low level rutine you want to run by additional parameter."
        lowLevel_printExistingRoutines
        exit 1
    fi

    SORTED_NAMES=`lowLevel_getExistingRoutines`

    if [[ $(echo "$SORTED_NAMES" | grep -e "$1") == "" ]]; then
        echo "Low level routine '$1' not found";
        lowLevel_printExistingRoutines
        exit 1
    fi

    COMMAND="$1 ${@:2}"
    $COMMAND
    return $?
}

function lowLevel_printExistingRoutines {
    echo ""
    echo "Existing routines"

    SORTED_NAMES=(`lowLevel_getExistingRoutines`)

    for SORTED_NAME in "${SORTED_NAMES[@]}"; do
        echo "    $SORTED_NAME";
    done
}


function lowLevel_getExistingRoutines {
    UGLY_NAMES=(`cat $SCRIPT_DIR/src/lowLevel/*.sh | grep -E '^[[:space:]]*([[:alnum:]_]+[[:space:]]*\(\)|function[[:space:]]+[[:alnum:]_]+)'`)
    declare -a NICE_NAMES
    for UGLY_NAME in "${UGLY_NAMES[@]}"; do
        TMP_A=`echo "${UGLY_NAME#function }" | xargs`
        if [[ $TMP_A == "{" ]] || [[ $TMP_A == "function" ]]; then
            continue;
        fi
        NICE_NAMES+=("$UGLY_NAME")
    done


    IFS=$'\n' SORTED_NAMES=($(sort <<< "${NICE_NAMES[*]}"))
    unset IFS

    echo "${NICE_NAMES[@]}"
}
