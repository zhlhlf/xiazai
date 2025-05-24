#!/bin/bash
i="$1"

sudo apt install yt-dlp ffmpeg >>/dev/null 2>&1 

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')

final=`yt-dlp --get-filename -o "%(uploader)s - ${name}.%(ext)s" "$i"`
echo "$final"

rm -rf a.ts*
yt-dlp --concurrent-fragments 8 -o "a.ts" " $i"
ffmpeg -loglevel error -i "a.ts" -c:v copy -c:a copy -bsf:v trace_headers -movflags +faststart "$final"
rm -rf a.ts*