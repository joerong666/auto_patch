#!/bin/env bash

if [ $# -ne 1 -o "$1" = "-h" ]; then
    echo "Usage: $0 <OUTPUT>"
    echo "<OUTPUT>: patch file like <OUTPUT>-patch20130607.tar.gz will be generated"
    echo "Attention: a manifest file named 'PATCH_MANIFEST' is needed under current directory"
    exit 1
fi

export LANG=en_US.UTF-8

patch_dir="$1-patch`date +'%Y%m%d'`"
manifest=PATCH_MANIFEST
patch_script=PATCH_SCRIPT

function err_out() {
    if [ -d "$patch_dir" ]; then
        rm -rf $patch_dir
    fi

    exit 1
}

function ok_out() {
    echo "Completed! Output to ${patch_dir}.tar.gz"
    if [ -d "$patch_dir" ]; then
        rm -rf $patch_dir
    fi

    exit 0
}

if [ ! -f $manifest ]; then
    echo "Manifest file '$manifest' is not found" >&2 
    err_out
fi

mkdir $patch_dir
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e '#!/bin/env bash\n
if [ $# -ne 2 ]; then
    echo "Usage: $0 <src_dir> <dest_dir>"
    exit 1
fi

src_dir=$1
dest_dir=$2
recover_dir=patch_recover_`date +"%Y%m%d%T" |sed "s/://g"`

set -x

export LANG=en_US.UTF-8
mkdir $dest_dir/$recover_dir
' >$patch_dir/$patch_script

( \
egrep -v '^#' $manifest \
|while read line
do
    op=`echo $line |awk -F: '{ print $2 }'`
    src_file=`echo $line |awk -F: '{ print $3 }'`
    file_name=`echo $src_file |awk -F/ '{print $NF}'`
    dest_path=`echo $line |awk -F: '{ print $4 }'`
    script_file=`echo $line |awk -F: '{ print $5 }'`

    if [ "$op" = "A" ]; then
        if [ -e "$src_file" ]; then
            if [ -z "$dest_path" ]; then
                cp -r --parent $src_file $patch_dir

                echo -e '\ncd $dest_dir'
                echo "cp -r --parent $src_file \$recover_dir"

                echo -e 'cd $src_dir'
                echo "cp -r --parent $src_file \$dest_dir"
            else
                mkdir -p $patch_dir/$dest_path
                cp -r $src_file $patch_dir/$dest_path

                echo -e '\ncd $dest_dir'
                echo "cp -r --parent $dest_path/$file_name \$recover_dir"

                echo -e 'cd $src_dir'
                echo "cp -r --parent $dest_path/$file_name \$dest_dir"
            fi
        else
            echo "WARN: $src_file does not exist, may be deleted by 'svn rm'" >&2
        fi
    fi

    if [ "$op" = "D" ]; then
        if [ -z "$dest_path" ]; then
            echo -e '\ncd $dest_dir'
            echo "cp -r --parent $src_file \$recover_dir"

            echo "rm -r \$dest_dir/$src_file"
        else
            echo -e '\ncd $dest_dir'
            echo "cp -r --parent $dest_path/$file_name \$recover_dir"

            echo "rm -r \$dest_dir/$dest_path/$file_name"
        fi
    fi

    if [ "$op" = "C" ]; then
        if [ -z "$dest_path" ]; then
            cp -r --parent $src_file $patch_dir

            echo -e '\ncd $src_dir'
            echo -e "chmod +x $src_file"
            echo -e "./$src_file \$src_dir \$dest_dir"
        else
            mkdir -p $patch_dir/$dest_path
            cp -r $src_file $patch_dir/$dest_path

            echo -e '\ncd $src_dir'
            echo -e "chmod +x $dest_path/$file_name"
            echo -e "./$dest_path/$file_name \$src_dir \$dest_dir"
        fi
    fi

done \
) \
>>  $patch_dir/$patch_script

chmod +x $patch_dir/$patch_script

find $patch_dir -type d -name '.svn' |xargs rm -rf
if [ $? -ne 0 ]; then
    err_out
fi

tar -zcf ${patch_dir}.tar.gz $patch_dir
if [ $? -ne 0 ]; then
    err_out
fi

ok_out

