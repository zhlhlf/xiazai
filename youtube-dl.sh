#!/bin/bash
i="$1"

sudo pip install youtube-dl >>/dev/null

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g')
name=$(echo "$name" | rev | tr -d ' ' | rev)

youtube-dl -o "$name.%(ext)s" "$i" --external-downloader aria2c --external-downloader-args "-x10" >> a.log 2>&1
echo "$name"
