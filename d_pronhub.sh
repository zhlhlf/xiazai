#!/bin/bash
urls="$1"; 
sudo apt install -y youtube-dl >> /dev/null

cd 666

for i in $urls;
do  
    #获取名字
    name=`curl -sL $i | grep inlineFree | cut -d'>' -f 2 | cut -d'<' -f 1`
    #去除一些特殊字符比如/等
    name=$(echo $name | tr -d '[:punct:]')
    #去除表情包  
    name=$(echo "$name" | perl -C -pe 's/[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}\x{1F680}-\x{1F6FF}\x{1F1E0}-\x{1F1FF}\x{2694}-\x{2699}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{1F900}-\x{1F95F}\x{1F980}-\x{1F9E0}]//g')
    #限制长度为65
    name="${name:0:60}"
  
    youtube-dl -o "$name.%(ext)s" $i --external-downloader aria2c --external-downloader-args "-x10" > ../a.log
    echo $name

done
