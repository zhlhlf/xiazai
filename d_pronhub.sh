#!/bin/bash
urls="$1"; 
sudo apt install -y youtube-dl >> /dev/null

cd 666

for i in $urls;
do  
    
    name=`curl -sL $i | grep inlineFree | cut -d'>' -f 2 | cut -d'<' -f 1`
    name="${name:0:65}"
    name=$(echo $name | tr -d '[:punct:]')
    youtube-dl -o "$name.%(ext)s" $i --external-downloader aria2c --external-downloader-args "-x10"
    echo $name

done
