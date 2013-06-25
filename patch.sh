#!/bin/env bash

if [ $# -ne 1 -o "$1" = "-h" ]; then
    echo "Usage: $0 patch.tar.gz"
    exit 1
fi

patch=$1

dest_path=`pwd`
tmp_dir="$HOME/._patch_tmp_`date +'%Y%m%d'`"

function err_out() {
    if [ -d "$tmp_dir" ]; then
        rm -rf $tmp_dir
    fi

    exit 1
}

function ok_out() {
    if [ -d "$tmp_dir" ]; then
        rm -rf $tmp_dir
    fi

    exit 0
}

rm -rf $tmp_dir
mkdir -p $tmp_dir
if [ $? -ne 0 ]; then
    err_out
fi

tar xf $patch -C $tmp_dir
if [ $? -ne 0 ]; then
    err_out
fi

script_file=PATCH_SCRIPT
src_path=`find $tmp_dir -type f -name "$script_file" |head -1 |sed "s#$script_file##"`
if [ -z "$src_path" ]; then
    echo "ERROR: No $script_file is found in $tmp_dir"
    err_out
fi

cd $src_path
ls -p |fgrep '/' |sed 's#/$##' |while read line
do
    if [ ! -d "$dest_path/$line" ]; then
        echo "ERROR: Sub-dir $line in patch tarball does not exist in $dest_path"
        err_out
    fi
done

log="$dest_path/patch_`date +'%Y%m%d'`.log"
./PATCH_SCRIPT $src_path $dest_path 2>&1 |sed 's#^+ ##' |tee $log

ok_out
