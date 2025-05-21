#!/bin/bash
i="$1"

pip install youtube-dl >>/dev/null 2>&1 

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')
echo "$name"

nohup youtube-dl -o "%(uploader)s - $name.%(ext)s" "$i" --external-downloader aria2c --external-downloader-args "-x10" >> $logfile 2>&1
