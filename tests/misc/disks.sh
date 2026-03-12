THIS_FOLDER=`dirname "${BASH_SOURCE[0]}"`

if isZfsEnabled; then
    source "$THIS_FOLDER/disksZfs.sh"
else
    source "$THIS_FOLDER/disksQcow2.sh"
fi
