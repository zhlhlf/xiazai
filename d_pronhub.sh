#!/bin/bash
urls="$1"; 
sudo pip install youtube-dl >> /dev/null

cd 666

for i in $urls;
do  
    #获取名字
    name=`curl -sL $i | grep inlineFree | cut -d'>' -f 2 | cut -d'<' -f 1`
    #name限制
    name=$(echo "$name" | perl -CSD -pe 's/[^\x{4E00}-\x{9FFF}\x{3040}-\x{309F}\x{30A0}-\x{30FF}a-zA-Z0-9 ]//g')
    #限制长度为60
    name="${name:0:60}"
  
    youtube-dl -o "$name.%(ext)s" $i --external-downloader aria2c --external-downloader-args "-x10" 
    echo $name

done
