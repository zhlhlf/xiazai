#!/bin/bash

install_if_missing ffmpeg yt-dlp

i="$1"

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')

final=`yt-dlp --get-filename -o "%(uploader)s - ${name}.%(ext)s" "$i"`
echo "$final"

z_f=$(uuidgen).ts

yt-dlp --concurrent-fragments $(nproc) -o $z_f "$i" --no-progress

# ffmpeg -loglevel error -threads 4 -i 'a.ts' \
# -c:v libx264 -crf 23 -preset veryfast \
# -x264-params "frame-threads=4:lookahead-threads=2" \
# -c:a aac -b:a 128k -movflags +faststart \
# "$final"

start(){
    start_time=$(date +%s)
    ffmpeg -loglevel error -threads $(nproc) -i $1 \
    -c:v copy -c:a copy \
    -movflags +faststart \
    "$final"
    
    end_time=$(date +%s)
    echo "Convert $((end_time - start_time))s -- $(du -h "$final")"
    rm -rf $1
}

start $z_f &
