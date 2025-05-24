#!/bin/bash
i="$1"

sudo apt install ffmpeg >>/dev/null 2>&1

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')

echo "$name"

URL=`curl -sL $i | grep 'html5player.setVideoHLS' | cut -d \' -f2`
base_vide=`curl -sL $URL | grep hls- | sort | head -n1 `
final_m3m8="$(dirname $URL)/$base_vide"
echo "下载链接：$final_m3m8"

ffmpeg -loglevel error -i "$final_m3m8" -c:v copy -c:a copy -bsf:v trace_headers -movflags +faststart "$name.mp4"
