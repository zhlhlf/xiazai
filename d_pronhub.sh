#!/bin/sh
urls="$1"; 
pip install youtube-dl
cd 666

for i in $urls;
    do  youtube-dl $i --external-downloader aria2c --external-downloader-args "-x10" 
done