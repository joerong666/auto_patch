#!/bin/env bash

src_dir=$1
dest_dir=$2

export LANG=en_US.UTF-8

target_dir=my_target/bin
target_proc=my_service

function err_out()
{
	echo "Reload my_service failed"	>&2
    exit 1
}

cd $dest_dir/$target_dir && \
./my_service reload

if [ $? -ne 0 ]; then
    err_out
fi

exit 0
