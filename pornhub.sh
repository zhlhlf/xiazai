#!/bin/bash

install_if_missing ffmpeg yt-dlp

i="$1"

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')

final=`yt-dlp --get-filename -o "%(uploader)s - ${name}.%(ext)s" "$i"`
echo "$final"

rm -rf a.ts*
yt-dlp --concurrent-fragments $(nproc) -o "a.ts" "$i" --no-progress

# ffmpeg -loglevel error -threads 4 -i 'a.ts' \
# -c:v libx264 -crf 23 -preset veryfast \
# -x264-params "frame-threads=4:lookahead-threads=2" \
# -c:a aac -b:a 128k -movflags +faststart \
# "$final"

ffmpeg -loglevel error -threads $(nproc) -i 'a.ts' \
-c:v copy -c:a copy \
-movflags +faststart \
"$final"

rm -rf a.ts*
