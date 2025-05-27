#!/bin/bash
i="$1"

sudo apt install ffmpeg >>/dev/null 2>&1

curl -sL "$i" > a
author=`grep html5player.setUploaderName a | cut -d \' -f 2`
name=`grep html5player.setVideoTitle a | cut -d \' -f 2`
name="$author - $name"

URL=`grep 'html5player.setVideoHLS' a | cut -d \' -f2`
base_vide=`curl -sL $URL | grep hls- | sort | head -n1 `
final_m3m8="$(dirname $URL)/$base_vide"
echo "下载链接：$final_m3m8"
echo $name
rm -rf a
ffmpeg -threads 8 -loglevel error -i "$final_m3m8" -c:v copy -c:a copy -bsf:v trace_headers -movflags +faststart "$name.mp4"
