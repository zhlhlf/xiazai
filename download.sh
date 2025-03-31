#!/bin/bash

mkdir -p 666
cd 666

logfile=a.log
touch $logfile
asd(){
    while true;do
        sleep 3
        tail -n 5 $logfile
        echo
    done
}
asd &

y_weblist="pornhub.com www.xvideos.com"

for i in $1; do
    if [ $(echo "$i" | grep "google.com/download") ]; then
        rm -rf dGoogleUrl.sh
        wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh
        chmod 777 * -R
        i=$(./dGoogleUrl.sh "$i")
        echo $i
    elif [ "1" ]; then
        yes=0
        for u in $y_weblist; do
            if [ $(echo $i | grep $u) ]; then
                ../youtube-dl.sh "$i"
                yes=1
                break
            fi
        done
        if [ "$yes" = "1" ]; then
            continue
        fi
    fi
    echo "UA: $3"
    aria2c -x$2 -U "$3" "$i" >> a.log 2>&1

done

rm -rf $logfile
