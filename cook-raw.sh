#!/usr/bin/env bash
#
#/ Usage:
#/   ./cook-raw.sh [--command] [file] [--option]
#/
#/ Command:
#/   --cook:                  cook all raw files
#/   --cooked:                add "cooked" tag in all final files
#/   --cookfile <file>:       cook a specific file
#/   --fry:                   convert raw file to jpg
#/   --wrap:                  create zip file
#/   --mix:                   mix zip file and jpg file
#/   --check:                 run a check
#/   --clean:                 remove temporary folders
#/   --unwrap:                extract raw files
#/
#/ Option:
#/   --extension <extension>: raw file extension name

set -e
set -u

usage() {
    # Display usage message
    printf "\n%b\n" "$(grep '^#/' "$0" | cut -c4-)" && exit 0
}

set_var() {
    # Define variables/ingredients
    [[ -z "${_RAW_EXTENSION:-}" ]] && _RAW_EXTENSION=".CR2"
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

isCommandExist() {
    # Check if command exist
    if [ ! "$(command -v "$1")" ]; then
        echo "$1 command doesn't exist!" && exit 1
    fi
}

setExtension() {
    # Return file extension
    if [ "${1:-}" == "" ]; then
        echo $_RAW_EXTENSION
    else
        echo ${_RAW_EXTENSION}${_RECIPE_EXTENSION}
    fi
}

findFile() {
    # Find file has certain extension and file name
    if [[ "${2:-}" == "" ]]; then
        find ./*"$1" -maxdepth 1 -type f
    else
        find ./*"$1" -maxdepth 1 -type f | grep "$2"
    fi
}

fry() {
    # Generate jpg file
    echo "::FRY::" >&2
    isCommandExist "dcraw"
    isCommandExist "cjpeg"

    mkdir -p $_JPG_OUTPUT

    extension=$(setExtension "${1:-}")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
    for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}

        echo "$n/$total Progressing file $raw..." >&2

        # convert raw to jpg
        dcraw -c -w "$raw" | cjpeg -quality $_JPG_QUALITY -optimize -progressive > "$jpg" || true

        n=$((n+1))
    done
}

wrap() {
    # Create zip file
    echo "::WRAP::" >&2
    isCommandExist "zip"

    mkdir -p $_ZIP_OUTPUT

    extension=$(setExtension "${1:-}")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
    for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        recipe=${basename}${_RAW_EXTENSION}${_RECIPE_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}
        zip=${_ZIP_OUTPUT}/${basename}.zip

        echo "$n/$total Zipping file $raw..." >&2

        if [[ "${1:-}" == "" ]]; then
            zip -j "$zip" "$raw" "$jpg"
        elif [[ "${1:-}" != "" && -f "$recipe" ]]; then
            zip -j "$zip" "$raw" "$jpg" "$recipe"
        else
            echo "Skip $raw" >&2
        fi

        n=$((n+1))
    done
}

mix() {
    # Mix zip and jpg
    echo "::MIX::" >&2
    mkdir -p $_FINAL_OUTPUT

    extension=$(setExtension "${1:-}")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
    for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        jpg=${_JPG_OUTPUT}/${basename}${_JPG_EXTENSION}
        zip=${_ZIP_OUTPUT}/${basename}.zip
        final=${_FINAL_OUTPUT}/${basename}-editable${1:-}${_JPG_EXTENSION}

        echo "$n/$total Mixing file $raw..." >&2

        # create final jpg
        cat "$jpg" "$zip" > "$final"

        # update Create Date of final jpg
        odate="$(exiftool "$raw" | grep 'Create Date' | head -1)"
        if [[ -n "${odate:-}" ]]; then
            exiftool -overwrite_original "-CreateDate=${odate}" "$final"
        fi

        n=$((n+1))
    done
}

check() {
    # Check cooked file
    echo "::CHECK::" >&2
    isCommandExist "unzip"
    isCommandExist "md5sum"

    mkdir -p $_CHECK_OUTPUT

    md5sum=${_CHECK_OUTPUT}/${_MD5SUM_FILE}
    true > $md5sum

    extension=$(setExtension "${1:-}")
    total=$(findFile "$extension" "$_FILE_SELECTED" | wc -w)
    n=1
    for i in $(findFile "$extension" "$_FILE_SELECTED"); do
        basename=$(basename "$i" "$extension")
        raw=${basename}${_RAW_EXTENSION}
        recipe=${basename}${_RAW_EXTENSION}${_RECIPE_EXTENSION}
        final=${_FINAL_OUTPUT}/${basename}-editable${1:-}${_JPG_EXTENSION}

        echo "$n/$total Preparing file $raw..." >&2

        # create md5sum file
        md5sum "$raw" >> $md5sum
        if [ "${1:-}" != "" ]; then
            md5sum "$recipe" >> $md5sum
        fi

        # unzip raw files
        unzip "$final" -d ${_CHECK_OUTPUT} 2> /dev/null || true

        n=$((n+1))
    done

    # checsum comparision
    cd "$_CHECK_OUTPUT" || return

    echo -e "\\nChecking files in $(pwd)..." >&2
    md5sum -c ${_MD5SUM_FILE}
    cd ..
}

unwrap() {
    # Extract raw files
    echo "::UNWRAP::" >&2
    isCommandExist "unzip"

    mkdir -p $_RAW_OUTPUT

    total=$(findFile "$_JPG_EXTENSION" "" | wc -w)
    n=1
    for i in $(findFile "$_JPG_EXTENSION" ""); do
        echo "$n/$total Extract file $i..." >&2
        unzip -o "$i" -d $_RAW_OUTPUT 2> /dev/null || true
        n=$((n+1))
    done
    # clean redundant jpg files
    rm -rf ${_RAW_OUTPUT:?}/*${_JPG_EXTENSION}
}

clean() {
    # Remove temporary folders
    rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT} 2> /dev/null || true
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
        echo "$1 doesn't exist." && exit 1
    fi

    _FILE_SELECTED="$1"
    extension=".${1##*.}"

    if [ "$extension" == "$_RAW_EXTENSION" ]; then
        cook
    elif [ "$extension" == "$_RECIPE_EXTENSION" ]; then
        cookRecipe
    else
        echo "Unsupport file type $extension" && exit 1
    fi

    _FILE_SELECTED=""
}

set_args() {
    # Declare arguments
    expr "$*" : ".*--help" > /dev/null && usage

    local key positional

    positional=()
    while [[ $# -gt 0 ]]; do
        key="$1"

        case $key in
            --cook)
                _CMD="cook"
                shift
                ;;
            --cooked)
                _CMD="cooked"
                shift
                ;;
            --cookfile)
                _CMD="cookfile"
                _FILE="${2:-}"
                shift
                shift
                ;;
            --fry)
                _CMD="fry"
                _FILE=""
                shift
                ;;
            --wrap)
                _CMD="wrap"
                _FILE=""
                shift
                ;;
            --mix)
                _CMD="mix"
                _FILE=""
                shift
                ;;
            --check)
                _CMD="check"
                _FILE=""
                shift
                ;;
            --clean)
                _CMD="clean"
                shift
                ;;
            --unwrap)
                _CMD="unwrap"
                shift
                ;;
            --extension)
                _RAW_EXTENSION="$2"
                shift
                shift
                ;;
            *)
                positional+=("$1")
                shift
            ;;
        esac
    done
    set -- "${positional[@]}"
}

main() {
    set_args "$@"
    set_var

    [[ -z "${_CMD:-}" ]] && cook
    [[ "${_CMD:-}" == "cook" ]] && cook
    [[ "${_CMD:-}" == "cooked" ]] && cookRecipe
    [[ "${_CMD:-}" == "cookfile" ]] && cookOneFile "$_FILE"
    [[ "${_CMD:-}" == "fry" ]] && fry "$_FILE"
    [[ "${_CMD:-}" == "wrap" ]] && wrap "$_FILE"
    [[ "${_CMD:-}" == "mix" ]] && mix "$_FILE"
    [[ "${_CMD:-}" == "check" ]] && check "$_FILE"
    [[ "${_CMD:-}" == "clean" ]] && clean
    [[ "${_CMD:-}" == "unwrap" ]] && unwrap
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
