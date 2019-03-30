#!/usr/bin/env bash

#/ Usage:
#/   ./cook-raw.sh [cook|cooked|cookfile|fry|wrap|mix|check|clean|unwrap] [file]
#/

###################
#
# INGREDIENTS
#
###################

set_var() {
    # Define variables/ingredients
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
}

###################
#
# METHODS
#
###################

usage() {
    # Print usage
    grep '^#/' "$0" | cut -c4-
    exit 0
}

isCommandExist() {
    # Check if command exist
    if [ ! "$(command -v $1)" ]; then
        echo "$1 command doesn't exist!"
        exit 1
    fi
}

setExtension() {
    # Return file extension
    if [ "$1" == "" ]; then
        echo $_RAW_EXTENSION
    else
        echo ${_RAW_EXTENSION}${_RECIPE_EXTENSION}
    fi
}

findFile() {
    # Find file has certain extension and file name
    find ./*"$1" -maxdepth 1 -type f | grep "$2"
}

fry() {
    # Generate jpg file
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

wrap() {
    # Create zip file
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

mix() {
    # Mix zip and jpg
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

check() {
    # Check cooked file
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

unwrap() {
    # Extract raw files
    echo "::UNWRAP::"
	isCommandExist "unzip"

	mkdir -p $_RAW_OUTPUT

    total=$(findFile "$_JPG_EXTENSION" "" | wc -w)
    n=1
	for i in $(findFile "$_JPG_EXTENSION" ""); do
		echo "$n/$total Extract file $i..."
		unzip -o "$i" -d $_RAW_OUTPUT 2> /dev/null
		n=$((n+1))
	done
	# clean redundant jpg files
	rm -rf ${_RAW_OUTPUT:?}/*${_JPG_EXTENSION}
}

clean() {
    # Remove temporary folders
    rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT} 2> /dev/null
}

cook() {
    clean
	fry
	wrap
	mix
    clean
	check
    clean
}

cookRecipe() {
    clean
    fry "recipe"
    wrap "recipe"
    mix "-cooked"
    clean
    check "-cooked"
    clean
}

cookOneFile() {
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

main() {
    set_var

    expr "$*" : ".*--help" > /dev/null && usage

    #/     cook:            cook all raw files
    [[ "$1" == "cook" || "$1" == "" ]] && cook

    #/     cooked:          add "cooked" tag in all final files
    [[ "$1" == "cooked" ]] && cookRecipe

    #/     cookfile <file>: cook a specific file
    [[ "$1" == "cookfile" ]] && cookOneFile "$2"

    #/     fry <file>:      convert raw file to jpg
    [[ "$1" == "fry" ]] && fry "$2"

    #/     wrap <file>:     create zip file
    [[ "$1" == "wrap" ]] && wrap "$2"

    #/     mix <file>:      mix zip file and jpg file
    [[ "$1" == "mix" ]] && mix "$2"

    #/     check <file>:    run a check
    [[ "$1" == "check" ]] && check "$2"

    #/     clean:           remove temporary folders
    [[ "$1" == "clean" ]] && clean

    #/     unwrap:          extract raw files
    [[ "$1" == "unwrap" ]] && unwrap
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
