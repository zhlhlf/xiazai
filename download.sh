#!/bin/bash


mkdir -p 666
cd 666

for i in $1;do
    if [ `echo "$i" | grep "google.com/download"` ];then
        rm -rf dGoogleUrl.sh; wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh ; chmod 777 * -R
        i=`./dGoogleUrl.sh "$i"`
        echo $i
    elif [ `echo "$i" | grep "pornhub.com"` ];then
        ../youtube-dl.sh "$i" 0
        continue
    elif [ `echo "$i" | grep "www.xvideos.com"` ];then
        youtube_dl=1
        ../youtube-dl.sh "$i" 1
        continue
    fi
    echo "UA: $3"
    aria2c -x$2 -U "$3" "$i"

done

