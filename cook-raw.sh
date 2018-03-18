#/bin/bash
_RAW_PATH=`pwd`
_RAW_SUFFIX="CR2"
_JPG_QUALITY=85
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

total=`ls *.${_RAW_SUFFIX} | wc -w`

# generate final jpg file
if [[ "$1" == "cook" || "$1" == "" ]];then
    isCommandExist "dcraw"
    isCommandExist "cjpeg"
    isCommandExist "zip"

    mkdir -p $_JPG_OUTPUT
    mkdir -p $_ZIP_OUTPUT
    mkdir -p $_FINAL_OUTPUT

    n=1
    for i in *.${_RAW_SUFFIX}; do
        raw=$i
        jpg=${_JPG_OUTPUT}/$i.jpg
        zip=${_ZIP_OUTPUT}/$i.zip
        final=${_FINAL_OUTPUT}/$(basename "$i" "$_RAW_SUFFIX")-editable.jpg

        echo "$n/$total Progressing file $raw..."

        # convert raw to jpg
        dcraw -c "$raw" | cjpeg -quality $_JPG_QUALITY -optimize -progressive > $(echo $jpg);

        # create zip including raw and jpg
        zip $zip $raw $jpg

        # create final jpg
        cat $jpg $zip > $final

        n=$((n+1))
    done
fi

# check cooked file
if [[ "$1" == "check" || "$1" == "" ]];then
    isCommandExist "unzip"
    isCommandExist "md5sum"

    mkdir -p $_CHECK_OUTPUT

    md5sum=${_CHECK_OUTPUT}/${_MD5SUM_FILE}
    > $md5sum

    n=1
    for i in *.${_RAW_SUFFIX}; do
        raw=$i
        raw_unzip=${_CHECK_OUTPUT}/$i
        final=${_FINAL_OUTPUT}/$(basename "$i" "$_RAW_SUFFIX")-editable.jpg

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
    cd $_RAW_PATH
fi

# clean temporary folders
if [[ "$1" == "clean" ]]; then
    rm -r ${_CHECK_OUTPUT} ${_ZIP_OUTPUT} ${_JPG_OUTPUT}
fi
