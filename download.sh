#!/bin/bash
export logfile="$(pwd)/dl.log"
touch $logfile

if [ ! -d 666 ]; then
    mkdir -p 666
fi

. utils.sh

cd 666


current=0
total_params=$(echo "$1" | wc -w)

for i in $1; do

    ((current++))
    echo "Processing item $current/$total_params: $i"
    
    if [ $(echo "$i" | grep "google.com/download") ]; then
        rm -rf dGoogleUrl.sh
        wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh
        chmod 777 * -R
        i=$(. dGoogleUrl.sh "$i")
        echo $i
    elif [ $(echo "$i" | grep "https://cn.pornhub.com/model/") ]; then
        . ../pornhub_getUserAllVides.sh "$i"
        u_list=$(cat tmp/*.txt)
        rm -rf tmp
        cd ..
        . download.sh "$u_list"
        cd 666
        continue
    elif [ $(echo "$i" | grep -E "pornhub.com|youtube.com") ]; then
        . ../pornhub.sh "$i"
        continue
    elif [ $(echo "$i" | grep "www.xvideos.com.*prof-video-click") ]; then
        . ../xvideos.sh "$i"
        continue
    elif [ $(echo "$i" | grep "www.xvideos.com") ]; then
        . ../xvideos_getUserAllVides.sh "$i"
        u_list=$(cat tmp/*.txt)
        rm -rf tmp
        cd ..
        . download.sh "$u_list"
        cd 666
        continue
    elif [ ${i: -5} == ".m3u8" ]; then
        install_if_missing ffmpeg 
        ffmpeg -loglevel info -threads $(nproc) -i "$i" \
        -c:v copy -c:a copy \
        -movflags +faststart \
        "a.mp4"
        mv "a.mp4" "$(md5sum "a.mp4" | awk '{ print $1 }').mp4"
    fi
    echo "aria2c  UA: $3"
    aria2c -x$2 -U "$3" "$i" 

done

rm -rf $logfile
