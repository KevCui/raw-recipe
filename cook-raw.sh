#!/usr/bin/env bash

###################
#
# INGREDIENTS
#
###################

_CURRENT_PATH="$(pwd)"
_RAW_EXTENSION=".CR2"
_RECIPE_EXTENSION=".xmp"
_JPG_EXTENSION=".jpg"
_JPG_QUALITY=85
_RAW_OUTPUT="./raw"
_JPG_OUTPUT="./jpg"
_ZIP_OUTPUT="./zip"
_FINAL_OUTPUT='./final'
_CHECK_OUTPUT="./check"
_MD5SUM_FILE="md5sum"
_FILE_SELECTED=""
_TEST_PATH="${_CURRENT_PATH}/test"

###################
#
# METHODS
#
###################

# Check if command exist
function isCommandExist() {
    if [ ! "$(command -v "$1")" ]; then
        echo "$1 command doesn't exist!"
        exit 1
    fi
}

# Return file extension
function setExtension() {
    if [ "$1" == "" ]; then
        echo $_RAW_EXTENSION
    else
        echo ${_RAW_EXTENSION}${_RECIPE_EXTENSION}
    fi
}

# Find file has certain extension and file name
function findFile() {
    find ./*"$1" -maxdepth 1 -type f | grep "$2"
}

# Generate jpg file
function fry() {
    echo "::FRY::"
	isCommandExist "dcraw"
	isCommandExist "cjpeg"

	mkdir -p $_JPG_OUTPUT

    extension=$(setExtension "$1")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
	n=1
	for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}

		echo "$n/$total Progressing file $raw..."

		# convert raw to jpg
		dcraw -c -w "$raw" | cjpeg -quality $_JPG_QUALITY -optimize -progressive > "$jpg";

		n=$((n+1))
	done
}

# Create zip file
function wrap() {
    echo "::WRAP::"
	isCommandExist "zip"

	mkdir -p $_ZIP_OUTPUT

    extension=$(setExtension "$1")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
	for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        recipe=${basename}${_RAW_EXTENSION}${_RECIPE_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}
        zip=${_ZIP_OUTPUT}/${basename}.zip

        echo "$n/$total Zipping file $raw..."

        if [[ "$1" == "" ]]; then
            zip -j "$zip" "$raw" "$jpg"
        elif [[ "$1" != "" && -f "$recipe" ]]; then
            zip -j "$zip" "$raw" "$jpg" "$recipe"
        else
            echo "Skip $raw"
        fi

        n=$((n+1))
    done
}

# Mix zip and jpg
function mix() {
    echo "::MIX::"
	mkdir -p $_FINAL_OUTPUT

    extension=$(setExtension "$1")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
	for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}
        zip=${_ZIP_OUTPUT}/${basename}.zip
        final=${_FINAL_OUTPUT}/${basename}-editable${1}${_JPG_EXTENSION}

        echo "$n/$total Mixing file $raw..."

        # create final jpg
        cat "$jpg" "$zip" > "$final"

        n=$((n+1))
    done
}

# Check cooked file
function check() {
    echo "::CHECK::"
    isCommandExist "unzip"
    isCommandExist "md5sum"

    mkdir -p $_CHECK_OUTPUT

    md5sum=${_CHECK_OUTPUT}/${_MD5SUM_FILE}
    true > $md5sum

    extension=$(setExtension "$1")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
	for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        recipe=${basename}${_RAW_EXTENSION}${_RECIPE_EXTENSION}
        final=${_FINAL_OUTPUT}/${basename}-editable${1}${_JPG_EXTENSION}

        echo "$n/$total Preparing file $raw..."

        # create md5sum file
        md5sum "$raw" >> $md5sum
        if [ "$1" != "" ]; then
            md5sum "$recipe" >> $md5sum
        fi

        # unzip raw files
        unzip "$final" -d ${_CHECK_OUTPUT} 2> /dev/null

        n=$((n+1))
    done

    # checsum comparision
    cd "$_CHECK_OUTPUT" || return

    echo -e "\\nChecking files in $(pwd)..."
    md5sum -c ${_MD5SUM_FILE}
    cd ..
}

# Extract raw files
function unwrap() {
    echo "::UNWRAP::"
	isCommandExist "unzip"

	mkdir $_RAW_OUTPUT

    total=$(findFile "$_JPG_EXTENSION" "" | wc -w)
    n=1
	for i in $(findFile "$_JPG_EXTENSION" ""); do
		echo "$n/$total Extract file $i..."
		unzip "$i" -d $_RAW_OUTPUT 2> /dev/null
		n=$((n+1))
	done
	# clean redundant jpg files
	rm -rf ${_RAW_OUTPUT:?}/*${_JPG_EXTENSION}
}

# Remove temporary folders
function clean() {
    rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT} 2> /dev/null
}

function cook() {
    clean
	fry
	wrap
	mix
    clean
	check
    clean
}

function cookRecipe() {
    clean
    fry "recipe"
    wrap "recipe"
    mix "-cooked"
    clean
    check "-cooked"
    clean
}

function cookOneFile() {
    if [ ! -f "$1" ]; then
        echo "$1 doesn't exist."
        exit 1
    fi

    _FILE_SELECTED="$1"
    extension=".${1##*.}"

    if [ "$extension" == "$_RAW_EXTENSION" ]; then
        cook
    elif [ "$extension" == "$_RECIPE_EXTENSION" ]; then
        cookRecipe
    else
        echo "Unsupport file type $extension"
        exit 1
    fi

    _FILE_SELECTED=""
}

###################
#
# COMMANDS
#
###################

[[ "$1" == "cook" || "$1" == "" ]] && cook

[[ "$1" == "cooked" ]] && cookRecipe

[[ "$1" == "cookfile" ]] && cookOneFile "$2"

[[ "$1" == "fry" ]] && fry "$2"

[[ "$1" == "wrap" ]] && wrap "$2"

[[ "$1" == "mix" ]] && mix "$2"

[[ "$1" == "check" ]] && check "$2"

[[ "$1" == "clean" ]] && clean

[[ "$1" == "unwrap" ]] && unwrap

###################
#
# TESTS
#
###################

if [[ "$1" == "test" ]]; then
    function checkFileExist() {
        [ -f "$1" ] && echo "CHECK $2: [PASS] $1 exists" || echo "CHECK $2: [F***] $1 doesn't exist"
    }

    function checkFileNotExist() {
        [ -f "$1" ] && echo "CHECK $2: [F***] $1 exists" || echo "CHECK $2: [PASS] $1 doesn't exist"
    }

    function checkFolderExist() {
        [ -d "$1" ] && echo "CHECK $2: [PASS] $1 exists" || echo "CHECK $2: [F***] $1 doesn't exist"
    }

    function checkFolderNotExist() {
        [ -d "$1" ] && echo "CHECK $2: [F***] $1 exists" || echo "CHECK $2: [PASS] $1 doesn't exist"
    }

    function checkmd5sum() {
        [[ $(md5sum "$1" | awk '{print $1}') == "$2" ]] && echo "CHECK $3: [PASS] $1 md5sum" || echo "CHECK $3: [F***] $1 md5sum"
    }

    function removeAll() {
        rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT} ${_FINAL_OUTPUT} 2>/dev/null
    }

    function silenceRun() {
        "$@" 1>/dev/null 2>/dev/null
    }

    # Preparation
    mkdir -p "$_TEST_PATH"
    cd "$_TEST_PATH" || return
    removeAll
    echo "001.raw" > IMG_001${_RAW_EXTENSION}
    echo "002.raw" > IMG_002${_RAW_EXTENSION}
    echo "002.raw.cooked" > IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION}

    [ "$(setExtension "new")" == "${_RAW_EXTENSION}${_RECIPE_EXTENSION}" ] && echo "CHECK 00: [PASS] setExtension" || echo "CHECK 00: [F***] setExtension"
    [ "$(setExtension)" == "${_RAW_EXTENSION}" ] && echo "CHECK 00: [PASS] setExtension" || echo "CHECK 00: [F***] setExtension"

    # TEST fry
    silenceRun fry
    checkFileExist ${_JPG_OUTPUT}/IMG_001${_JPG_EXTENSION} 01
    checkFileExist ${_JPG_OUTPUT}/IMG_002${_JPG_EXTENSION} 02

    # TEST wrap
    silenceRun wrap
    checkFileExist ${_ZIP_OUTPUT}/IMG_001.zip 03
    checkFileExist ${_ZIP_OUTPUT}/IMG_002.zip 04

    # TEST mix
    silenceRun mix
    checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 05
    checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 06

    # TEST check
    silenceRun check
    checkFileExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION} 07
    checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION}${_RECIPE_EXTENSION} 08
    checkFileExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION} 09
    checkFileNotExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} 10
    checkFileExist ${_CHECK_OUTPUT}/IMG_001${_JPG_EXTENSION} 11
    checkFileExist ${_CHECK_OUTPUT}/IMG_002${_JPG_EXTENSION} 12
    checkmd5sum ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION} "92489c7597f2eac4731a3e21ab8f28ba" 13
    checkmd5sum ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION} "bbd7831aad5d635f8a84314103b39f65" 14
    checkmd5sum ${_CHECK_OUTPUT}/md5sum "7680e1205ea004a77df4ce44f5ad353e" 15

    # TEST clean
    silenceRun clean
    checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 16
    checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 17
    checkFolderNotExist ${_JPG_OUTPUT} 18
    checkFolderNotExist ${_ZIP_OUTPUT} 19
    checkFolderNotExist ${_CHECK_OUTPUT} 20

    # TEST fry $1
    removeAll
    silenceRun fry "recipe"
    checkFileNotExist ${_JPG_OUTPUT}/IMG_001${_JPG_EXTENSION} 21
    checkFileExist ${_JPG_OUTPUT}/IMG_002${_JPG_EXTENSION} 22

    # TEST wrap $1
    silenceRun wrap "recipe"
    checkFileNotExist ${_ZIP_OUTPUT}/IMG_001.zip 23
    checkFileExist ${_ZIP_OUTPUT}/IMG_002.zip 24

    # TEST mix $1
    silenceRun mix "-cooked"
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION} 25
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 26
    checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION} 27
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 28

    # TEST check $1
    silenceRun check "-cooked"
    checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION} 29
    checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION}${_RECIPE_EXTENSION} 30
    checkFileExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION} 31
    checkFileExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} 32
    checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_JPG_EXTENSION} 33
    checkFileExist ${_CHECK_OUTPUT}/IMG_002${_JPG_EXTENSION} 34
    checkmd5sum ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION} "bbd7831aad5d635f8a84314103b39f65" 35
    checkmd5sum ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} "a3881ec11cbe57244631037cb313f686" 36
    checkmd5sum ${_CHECK_OUTPUT}/md5sum "7ea84f0f49a4b4055315d9ba66b828d6" 37

    # TEST unwrap
    cd "${_FINAL_OUTPUT}" || return
    silenceRun unwrap
    checkFileExist ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION} 38
    checkFileExist ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} 39
    checkFileNotExist ${_RAW_OUTPUT}/IMG_002${_JPG_EXTENSION} 40
    checkmd5sum ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION} "bbd7831aad5d635f8a84314103b39f65" 41
    checkmd5sum ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} "a3881ec11cbe57244631037cb313f686" 42
    cd "${_TEST_PATH}" || return

    # TEST cookOneFile raw file
    removeAll
    silenceRun cookOneFile "IMG_001${_RAW_EXTENSION}"
    checkFolderNotExist ${_JPG_OUTPUT} 43
    checkFolderNotExist ${_ZIP_OUTPUT} 44
    checkFolderNotExist ${_CHECK_OUTPUT} 45
    checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 46
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION} 47
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 48
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION} 49

    # TEST cookOneFile recipe file
    removeAll
    silenceRun cookOneFile "IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION}"
    checkFolderNotExist ${_JPG_OUTPUT} 50
    checkFolderNotExist ${_ZIP_OUTPUT} 51
    checkFolderNotExist ${_CHECK_OUTPUT} 52
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 53
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION} 54
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 55
    checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION} 56

    # TEST cook
    removeAll
    silenceRun cook
    checkFolderNotExist ${_JPG_OUTPUT} 57
    checkFolderNotExist ${_ZIP_OUTPUT} 58
    checkFolderNotExist ${_CHECK_OUTPUT} 59
    checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 60
    checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 61

    # TEST cookRecipe
    removeAll
    silenceRun cookRecipe
    checkFolderNotExist ${_JPG_OUTPUT} 63
    checkFolderNotExist ${_ZIP_OUTPUT} 64
    checkFolderNotExist ${_CHECK_OUTPUT} 65
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION} 66
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION} 67
    checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION} 68
    checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION} 69

    echo "DONE"
fi
