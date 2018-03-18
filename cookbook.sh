#!/bin/bash

_CURRENT_PATH=`pwd`
_RAW_SUFFIX=".CR2"
_RECIPE_SUFFIX=".xmp"
_JPG_SUFFIX=".jpg"
_JPG_QUALITY=85
_RAW_OUTPUT="./raw"
_JPG_OUTPUT="./jpg"
_ZIP_OUTPUT="./zip"
_FINAL_OUTPUT='./final'
_CHECK_OUTPUT="./check"
_MD5SUM_FILE="md5sum"

function isExist() {
    if [ ! `command -v $1` ]; then
        echo "$1 command doesn't exist!"
        exit 1
    fi
}

# Generate jpg file
function fry() {
	isExist "dcraw"
	isExist "cjpeg"

	mkdir -p $_JPG_OUTPUT

	n=1
	for i in *${_RAW_SUFFIX}; do
		raw=$i
		jpg=${_JPG_OUTPUT}/$i.jpg
		total=`ls *${_RAW_SUFFIX} | wc -w`

		echo "$n/$total Progressing file $raw..."

		# convert raw to jpg
		dcraw -c "$raw" | cjpeg -quality $_JPG_QUALITY -optimize -progressive > $(echo $jpg);

		n=$((n+1))
	done
}

# Create zip file
function wrap() {
	isExist "zip"

	mkdir -p $_ZIP_OUTPUT

    n=1
    for i in *${_RAW_SUFFIX}; do
        raw=$i
		recipe=${i}${_RECIPE_SUFFIX}
        jpg=${_JPG_OUTPUT}/$i.jpg
        zip=${_ZIP_OUTPUT}/$i.zip
		total=`ls *${_RAW_SUFFIX} | wc -w`

        echo "$n/$total Ziping file $raw..."

        # create zip including raw, jpg and editor file
        zip $zip $raw $jpg $recipe

        n=$((n+1))
    done
}

# Mix zip and jpg
function mix() {
	mkdir -p $_FINAL_OUTPUT

    n=1
    for i in *${_RAW_SUFFIX}; do
        raw=$i
        jpg=${_JPG_OUTPUT}/$i.jpg
        zip=${_ZIP_OUTPUT}/$i.zip
        final=${_FINAL_OUTPUT}/$(basename "$i" "${_RAW_SUFFIX}")-editable${1}.jpg
		total=`ls *${_RAW_SUFFIX} | wc -w`

        echo "$n/$total Mixing file $raw..."

        # create final jpg
        cat $jpg $zip > $final

        n=$((n+1))
    done

}

# Check cooked file
function check() {
    isExist "unzip"
    isExist "md5sum"

    mkdir -p $_CHECK_OUTPUT

    md5sum=${_CHECK_OUTPUT}/${_MD5SUM_FILE}
    > $md5sum

    n=1
    for i in *${_RAW_SUFFIX}; do
        raw=$i
        raw_unzip=${_CHECK_OUTPUT}/$i
        final=${_FINAL_OUTPUT}/$(basename "$i" "$_RAW_SUFFIX")-editable.jpg
		total=`ls *${_RAW_SUFFIX} | wc -w`

        echo "$n/$total Preparing file $raw..."

        # create md5sum file
        md5sum $raw >> $md5sum

        # unzip raw files
        unzip -p $final $raw > ${_CHECK_OUTPUT}/$raw 2> /dev/null

        n=$((n+1))
    done

    # checsum comparision
    cd $_CHECK_OUTPUT
    echo -e "\nChecking raw files in `pwd`..."
    md5sum -c ${_MD5SUM_FILE}
    cd $_CURRENT_PATH
}

# Extract raw files
function unwrap() {
	isExist "unzip"

	mkdir $_RAW_OUTPUT

	total=`ls *{_JPG_SUFFIX} | wc -w`
	n=1
	for i in *${_JPG_SUFFIX}; do
		echo "$n/$total Extract file $i..."
		unzip $i -d $_RAW_OUTPUT 2> /dev/null
		n=$((n+1))
	done

	# clean redundant jpg files
	rm -rf ${_RAW_OUTPUT}/jpg
}

# Remove temporary folders
function clean() {
     rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT}
}
