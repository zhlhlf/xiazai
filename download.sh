#!/bin/bash

export logfile="$(pwd)/dl.log"
touch $logfile

mkdir -p 666
cd 666


# asd(){
#     while true;do
#         sleep 5
#         tail -n 1 $logfile
#         echo
#     done
# }

# asd &

out_pid=$!

current=0
total_params=$(echo "$1" | wc -w)

for i in $1; do

    ((current++))
    echo "Processing item $current/$total_params: $i"

    if [ $(echo "$i" | grep "google.com/download") ]; then
        rm -rf dGoogleUrl.sh
        wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh
        chmod 777 * -R
        i=$(./dGoogleUrl.sh "$i")
        echo $i
    elif [ $(echo "$i" | grep "https://cn.pornhub.com/model/") ]; then
        ../pornhub_getUserAllVides.sh "$i"
        u_list=`cat tmp/*.txt`
        rm -rf tmp
        cd ..
        ./download.sh "$u_list"
        continue
    elif [ $(echo "$i" | grep "pornhub.com") ]; then
        ../pornhub.sh "$i"
        continue
    elif [ $(echo "$i" | grep "www.xvideos.com.*prof-video-click") ]; then
        ../xvideos.sh "$i"
        continue
    elif [ $(echo "$i" | grep "www.xvideos.com") ]; then
        ../xvideos_getUserAllVides.sh "$i"
        u_list=`cat tmp/*.txt`
        rm -rf tmp
        cd ..
        ./download.sh "$u_list"
        continue
    fi
    echo "UA: $3"
    aria2c -x$2 -U "$3" "$i" >> $logfile 2>&1

done

kill $out_pid >> /dev/null 2>&1
rm -rf $logfile

