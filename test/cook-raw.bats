#!/usr/bin/env bats
#
# How to run:
#   ~$ bats test/cow-raw.bats
#

BATS_TEST_SKIPPED=

setup() {
    _SCRIPT="cook-raw.sh"
    _HOME="$(pwd)"
    _TEST_OUTPUT="$_HOME/test"
    _RAW_EXTENSION=".CR2"
    _RECIPE_EXTENSION=".xmp"
    _JPG_EXTENSION=".jpg"
    _JPG_QUALITY=85
    _JPG_OUTPUT="$_TEST_OUTPUT/jpg"
    _ZIP_OUTPUT="$_TEST_OUTPUT/zip"
    _FINAL_OUTPUT="$_TEST_OUTPUT/final"
    _CHECK_OUTPUT="$_TEST_OUTPUT/check"
    _MD5SUM_FILE="md5sum"
    _FILE_SELECTED=""

    teardown

    echo "001.raw" > "$_TEST_OUTPUT/IMG_001${_RAW_EXTENSION}"
    echo "002.raw" > "$_TEST_OUTPUT/IMG_002${_RAW_EXTENSION}"
    echo "002.raw.cooked" > "$_TEST_OUTPUT/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION}"

    source "$_SCRIPT"
}

teardown() {
    cd "$_TEST_OUTPUT"
    rm -f IMG_001* IMG_002*
    rm -rf "$_CHECK_OUTPUT" "$_ZIP_OUTPUT" "$_JPG_OUTPUT" "$_FINAL_OUTPUT" 2>/dev/null
    cd "$_HOME"
}

checkFileExist() {
	[ -f "$1" ] && echo "PASS" || echo "F***"
}

checkFileNotExist() {
    [ -f "$1" ] && echo "F***" || echo "PASS"
}

checkFolderExist() {
    [ -d "$1" ] && echo "PASS" || echo "F***"
}

checkFolderNotExist() {
    [ -d "$1" ] && echo "F***" || echo "PASS"
}

checkmd5sum() {
    [[ $(md5sum "$1" | awk '{print $1}') == "$2" ]] && echo "PASS" || echo "F***"
}

@test "CHECK: isCommandExist() command exists" {
    run isCommandExist "bats"
    [ "$status" -eq 0 ]
}

@test "CHECK: isCommandExist() command doesn't exist" {
    run isCommandExist "thiscommandshouldnotexist"
    [ "$status" -eq 1 ]
    [ "$output" = "thiscommandshouldnotexist command doesn't exist!" ]
}

@test "CHECK: setExtension() default extension" {
    _RAW_EXTENSION="rawextension"
    run setExtension
    [ "$status" -eq 0 ]
    [ "$output" = "$_RAW_EXTENSION" ]
}

@test "CHECK: setExtension() recipe extension" {
    _RAW_EXTENSION="rawextension"
    _RECIPE_EXTENSION="recipe"
    run setExtension true
    [ "$status" -eq 0 ]
    [ "$output" = "${_RAW_EXTENSION}${_RECIPE_EXTENSION}" ]
}

@test "CHECK: findFile() find IMG_001.CR2" {
    cd $_TEST_OUTPUT
    run findFile "CR2" "001"
    [ "$status" -eq 0 ]
    [ "$output" = "./IMG_001.CR2" ]
}

@test "CHECK: findFile() no matches" {
    cd $_TEST_OUTPUT
    run findFile "CR2" "filedoesnotexist"
    [ "$status" -eq 1 ]
    [ "$output" = "" ]
}

@test "CHECK: clean()" {
    mkdir -p "$_CHECK_OUTPUT"
    mkdir -p "$_ZIP_OUTPUT"
    mkdir -p "$_JPG_OUTPUT"
    [ "$(checkFolderExist $_CHECK_OUTPUT)" = "PASS" ]
    [ "$(checkFolderExist $_ZIP_OUTPUT)" = "PASS" ]
    [ "$(checkFolderExist $_JPG_OUTPUT)" = "PASS" ]
    run clean
    [ "$status" -eq 0 ]
    [ "$(checkFolderNotExist $_CHECK_OUTPUT)" = "PASS" ]
    [ "$(checkFolderNotExist $_ZIP_OUTPUT)" = "PASS" ]
    [ "$(checkFolderNotExist $_JPG_OUTPUT)" = "PASS" ]
}

@test "CHECK: cook-raw.sh clean" {
    set_var() {
        echo "" > /dev/null
    }
    mkdir -p "$_CHECK_OUTPUT"
    mkdir -p "$_ZIP_OUTPUT"
    mkdir -p "$_JPG_OUTPUT"
    [ "$(checkFolderExist $_CHECK_OUTPUT)" = "PASS" ]
    [ "$(checkFolderExist $_ZIP_OUTPUT)" = "PASS" ]
    [ "$(checkFolderExist $_JPG_OUTPUT)" = "PASS" ]
    run main clean
    [ "$(checkFolderNotExist $_CHECK_OUTPUT)" = "PASS" ]
    [ "$(checkFolderNotExist $_ZIP_OUTPUT)" = "PASS" ]
    [ "$(checkFolderNotExist $_JPG_OUTPUT)" = "PASS" ]
}

@test "CHECK: fry()" {
    cd "$_TEST_OUTPUT"
    run fry
    [ "$status" -eq 0 ]
    [ "$(checkFileExist ${_JPG_OUTPUT}/IMG_001${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_JPG_OUTPUT}/IMG_002${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: cook-raw.sh fry recipe" {
    cd "$_TEST_OUTPUT"
    run main fry "recipe"
    [ "$(checkFileNotExist ${_JPG_OUTPUT}/IMG_001${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_JPG_OUTPUT}/IMG_002${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: wrap()" {
    cd "$_TEST_OUTPUT"
    run main fry
    run wrap
    [ "$status" -eq 0 ]
    [ "$(checkFileExist ${_ZIP_OUTPUT}/IMG_001.zip)" = "PASS" ]
    [ "$(checkFileExist ${_ZIP_OUTPUT}/IMG_002.zip)" = "PASS" ]
}

@test "CHECK: cook-raw.sh wrap recipe" {
    cd "$_TEST_OUTPUT"
    run main fry "recipe"
    run main wrap "recipe"
    [ "$(checkFileNotExist ${_ZIP_OUTPUT}/IMG_001.zip)" = "PASS" ]
    [ "$(checkFileExist ${_ZIP_OUTPUT}/IMG_002.zip)" = "PASS" ]
}

@test "CHECK: mix()" {
    cd "$_TEST_OUTPUT"
    run main fry
    run main wrap
    run mix
    [ "$status" -eq 0 ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: cook-raw.sh mix -cooked" {
    cd "$_TEST_OUTPUT"
    run main fry "recipe"
    run main wrap "recipe"
    run main mix "-cooked"
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-cooked${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: check()" {
    cd "$_TEST_OUTPUT"
    run main fry
    run main wrap
    run main mix
    run check
    [ "$status" -eq 0 ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION}${_RECIPE_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_001${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_002${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkmd5sum ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION} 92489c7597f2eac4731a3e21ab8f28ba)" = "PASS" ]
    [ "$(checkmd5sum ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION} bbd7831aad5d635f8a84314103b39f65)" = "PASS" ]
    [ "$(checkmd5sum ${_CHECK_OUTPUT}/md5sum 7680e1205ea004a77df4ce44f5ad353e)" = "PASS" ]
}

@test "CHECK: cook-raw.sh check -cooked" {
    cd "$_TEST_OUTPUT"
    run main fry "recipe"
    run main wrap "recipe"
    run main mix "-cooked"
    run main check "-cooked"
    [ "$(checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_RAW_EXTENSION}${_RECIPE_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_CHECK_OUTPUT}/IMG_001${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_CHECK_OUTPUT}/IMG_002${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkmd5sum ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION} bbd7831aad5d635f8a84314103b39f65)" = "PASS" ]
    [ "$(checkmd5sum ${_CHECK_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} a3881ec11cbe57244631037cb313f686)" = "PASS" ]
    [ "$(checkmd5sum ${_CHECK_OUTPUT}/md5sum 7ea84f0f49a4b4055315d9ba66b828d6)" = "PASS" ]
}

@test "CHECK: cook-raw.sh unwrap" {
    _RAW_OUTPUT="./raw"
    cd "$_TEST_OUTPUT"
    run main fry "recipe"
    run main wrap "recipe"
    run main mix "-cooked"
    run main check "-cooked"
    cd "$_FINAL_OUTPUT"
    run main unwrap
    [ "$status" -eq 0 ]
    [ "$(checkFileExist ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_RAW_OUTPUT}/IMG_002${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkmd5sum ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION} bbd7831aad5d635f8a84314103b39f65)" = "PASS" ]
    [ "$(checkmd5sum ${_RAW_OUTPUT}/IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION} a3881ec11cbe57244631037cb313f686)" = "PASS" ]
}

@test "CHECK: cookOneFile() raw file" {
    cd "$_TEST_OUTPUT"
    run cookOneFile "IMG_001${_RAW_EXTENSION}"
    [ "$status" -eq 0 ]
    [ "$(checkFolderNotExist ${_JPG_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_ZIP_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_CHECK_OUTPUT})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: cookOneFile() recipe file" {
    cd "$_TEST_OUTPUT"
    run cookOneFile "IMG_002${_RAW_EXTENSION}${_RECIPE_EXTENSION}"
    [ "$status" -eq 0 ]
    [ "$(checkFolderNotExist ${_JPG_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_ZIP_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_CHECK_OUTPUT})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: cook()" {
    cd "$_TEST_OUTPUT"
    run cook
    [ "$status" -eq 0 ]
    [ "$(checkFolderNotExist ${_JPG_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_ZIP_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_CHECK_OUTPUT})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
}

@test "CHECK: cookRecipe()" {
    cd "$_TEST_OUTPUT"
    run cookRecipe
    [ "$status" -eq 0 ]
    [ "$(checkFolderNotExist ${_JPG_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_ZIP_OUTPUT})" = "PASS" ]
    [ "$(checkFolderNotExist ${_CHECK_OUTPUT})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_001-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileNotExist ${_FINAL_OUTPUT}/IMG_002-editable${_JPG_EXTENSION})" = "PASS" ]
    [ "$(checkFileExist ${_FINAL_OUTPUT}/IMG_002-editable-cooked${_JPG_EXTENSION})" = "PASS" ]
}
