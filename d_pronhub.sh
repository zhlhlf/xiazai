#!/bin/bash
urls="$1"; 
sudo apt install -y youtube-dl >> /dev/null

cd 666

for i in $urls;
do  
    #获取名字
    name=`curl -sL $i | grep inlineFree | cut -d'>' -f 2 | cut -d'<' -f 1`
    #name限制
    name=$(echo "$name" | perl -C -pe 's/[^a-zA-Z0-9\p{Han}\p{Hiragana}\p{Katakana}]//g')
    #限制长度为60
    name="${name:0:60}"
  
    youtube-dl -o "$name.%(ext)s" $i --external-downloader aria2c --external-downloader-args "-x10" > ../a.log
    echo $name

done
