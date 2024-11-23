#!/bin/sh

for i in $1;do

    if [ `echo "$i" | grep "google.com/download"` ];then
    rm -rf dGoogleUrl.sh; wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh
        i=`./dGoogleUrl.sh "$i"`
    elif [ `echo "$i" | grep "pronhub.com"` ];then
        ./d_pronhub.sh "$i"
        continue
    fi
    aria2c -x$2 -U "$3" "$i" -d 666

done

