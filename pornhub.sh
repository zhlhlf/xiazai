#!/bin/bash
i="$1"

sudo apt install youtube-dl >>/dev/null 2>&1

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')

youtube-dl -o "$name.%(ext)s" "$i" --external-downloader aria2c --external-downloader-args "-x10"
echo "$name"
