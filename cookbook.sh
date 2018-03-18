#!/bin/bash

_CURRENT_PATH=`pwd`
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

function isCommandExist() {
    if [ ! `command -v $1` ]; then
        echo "$1 command doesn't exist!"
        exit 1
    fi
}


function setExtension() {
    if [ "$1" == "" ]; then
        echo $_RAW_EXTENSION
    else
        echo ${_RAW_EXTENSION}${_RECIPE_EXTENSION}
    fi
}

# Generate jpg file
function fry() {
    echo "::FRY::"
	isCommandExist "dcraw"
	isCommandExist "cjpeg"

	mkdir -p $_JPG_OUTPUT

    extension=`setExtension $1`
    total=`ls *${extension} | wc -w`
	n=1
	for i in *${extension}; do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}

		echo "$n/$total Progressing file $raw..."

		# convert raw to jpg
		dcraw -c "$raw" | cjpeg -quality $_JPG_QUALITY -optimize -progressive > $(echo $jpg);

		n=$((n+1))
	done
}

# Create zip file
function wrap() {
    echo "::WRAP::"
	isCommandExist "zip"

	mkdir -p $_ZIP_OUTPUT

    extension=`setExtension $1`
    total=`ls *${extension} | wc -w`
    n=1
    for i in *${extension}; do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        recipe=${basename}${_RAW_EXTENSION}${_RECIPE_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}
        zip=${_ZIP_OUTPUT}/${basename}.zip
        action=true

        echo "$n/$total Ziping file $raw..."

        if [[ "$1" == "" ]]; then
            zip -j $zip $raw $jpg
        elif [[ "$1" != "" && -f "$recipe" ]]; then
            zip -j $zip $raw $jpg $recipe
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

    extension=`setExtension $1`
    total=`ls *${extension} | wc -w`
    n=1
    for i in *${extension}; do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}
        zip=${_ZIP_OUTPUT}/${basename}.zip
        final=${_FINAL_OUTPUT}/${basename}-editable${1}${_JPG_EXTENSION}

        echo "$n/$total Mixing file $raw..."

        # create final jpg
        cat $jpg $zip > $final

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
    > $md5sum

    extension=`setExtension $1`
    total=`ls *${extension} | wc -w`
    n=1
    for i in *${extension}; do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        recipe=${basename}${_RAW_EXTENSION}${_RECIPE_EXTENSION}
        final=${_FINAL_OUTPUT}/${basename}-editable${1}${_JPG_EXTENSION}

        echo "$n/$total Preparing file $raw..."

        # create md5sum file
        md5sum $raw >> $md5sum
        if [ "$1" != "" ]; then
            md5sum $recipe >> $md5sum
        fi

        # unzip raw files
        unzip $final -d ${_CHECK_OUTPUT} 2> /dev/null

        n=$((n+1))
    done

    # checsum comparision
    cd $_CHECK_OUTPUT
    echo -e "\nChecking files in `pwd`..."
    md5sum -c ${_MD5SUM_FILE}
    cd $_CURRENT_PATH
}

# Extract raw files
function unwrap() {
    echo "::UNWRAP::"
	isCommandExist "unzip"

	mkdir $_RAW_OUTPUT

	total=`ls *{_JPG_EXTENSION} | wc -w`
	n=1
	for i in *${_JPG_EXTENSION}; do
		echo "$n/$total Extract file $i..."
		unzip $i -d $_RAW_OUTPUT 2> /dev/null
		n=$((n+1))
	done

	# clean redundant jpg files
	rm -rf ${_RAW_OUTPUT}/*${_JPG_EXTENSION}
}

# Remove temporary folders
function clean() {
     rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT} 2> /dev/null
}
