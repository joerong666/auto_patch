#!/bin/env bash

if [ $# -lt 1 -o "$1" = "-h" ]; then
    echo "Usage: $0 revision1[:revision2] [sub_dir]"
    exit 1
fi

export LANG=en_US.UTF-8

rev1=`echo $1 |awk -F':' '{print $1}'`
rev2=`echo $1 |awk -F':' '{print $2}'`
sub_dir=$2

if [ -z "$rev2" ]; then
    rev2=`svn info |awk '/Revision/{print $2}'`
fi

if [ -z "$sub_dir" ]; then
    sub_dir=".*"
else
    sub_dir=":$sub_dir"
fi

repo_root=`svn info |awk '/Repository Root:/{print $NF}'`
curr_url=`svn info |awk '/URL:/{print $NF}'`
curr_url=`echo $curr_url |sed "s#$repo_root##"`

svn log -r $rev1:$rev2 -v \
|egrep '^r[0-9]+ |^\s+A |^\s+M |^\s+D ' \
|awk '{ if($0 ~ /^r/) {rev = $1;} else { if($1 == "M") $1 = "A"; print rev" "$1" "$2; }}' \
|sort -r -t ' ' -k3 -k2 \
|uniq -f1 \
|sort -t ' ' -k1 \
|awk '{print $1":"$2":"$3}' \
|sed "s#:$curr_url/#:#" \
|egrep "$sub_dir" \
|awk 'BEGIN { print "#revision:A/D/C:src_file[:dest_dir]" } {print}'
