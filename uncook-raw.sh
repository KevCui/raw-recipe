#!/bin/bash

_EDITABLE_SUFFIX=".jpg"
_RAW_PATH='./raw'

function isCommandExist() {
    if [ ! `command -v $1` ]; then
        echo "$1 command doesn't exist!"
        exit 1
    fi
}

isCommandExist "unzip"
mkdir $_RAW_PATH

total=`ls *{_EDITABLE_SUFFIX} | wc -w`
n=1
for i in *${_EDITABLE_SUFFIX}; do
    echo "$n/$total Extract file $i..."
    unzip $i -d $_RAW_PATH 2> /dev/null
    n=$((n+1))
done

# clean redundant jpg files
rm -rf ${_RAW_PATH}/jpg
