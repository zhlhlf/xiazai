#!/bin/bash

# https://www.xvideos.com/channels/stockingscat/videos/best/0

mkdir -p tmp

i=$1
author=$(echo $i | cut -d'/' -f4)
echo "Author: $author"
num=0

while true; do
    echo "Page: $num"
    url="https://www.xvideos.com/channels/$author/videos/best/$num"

    list=`curl -sL $url | jq '.videos[].u'| sed 's/"//g'`
    if [ -z "$list" ]; then
        break
    fi
    for i in $list; do
        echo "https://www.xvideos.com$i" >> tmp/$author.txt
    done
    num=$((num + 1))
done