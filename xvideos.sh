#!/bin/bash

install_if_missing ffmpeg 

i="$1"

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

# ffmpeg -loglevel error -threads 4 -i "$final_m3m8"\
# -c:v libx264 -crf 23 -preset veryfast \
# -x264-params "frame-threads=4:lookahead-threads=2" \
# -c:a aac -b:a 128k -movflags +faststart \
# "$name.mp4"

ffmpeg -loglevel error -threads $(nproc) -i "$final_m3m8" \
-c:v copy -c:a copy \
-movflags +faststart \
"$name.mp4"

