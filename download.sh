#!/bin/sh

rm -rf dGoogleUrl.sh; wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh ; chmod 777 * -R
rm -rf upload-wetransfer.py; wget -q https://github.com/zhlhlf/text/raw/refs/heads/main/upload/upload-wetransfer.py
   
for i in $1;do
    if [ `echo "$i" | grep "google.com/download"` ];then
        i=`./dGoogleUrl.sh "$i"`
        echo $i
    elif [ `echo "$i" | grep "pornhub.com"` ];then
        ./d_pronhub.sh "$i"
        continue
    fi
    aria2c -x$2 -U "$3" "$i" -d 666

done

