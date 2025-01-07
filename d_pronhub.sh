#!/bin/sh
urls="$1"; 
sudo apt install -y youtube-dl >> /dev/null

cd 666

for i in $urls;
do  
    
    name=`curl -sL $i | grep inlineFree | cut -d'>' -f 2 | cut -d'<' -f 1`
    youtube-dl -o "${name:0:65}.%(ext)s" $i --external-downloader aria2c --external-downloader-args "-x10" 

done