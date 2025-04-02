#!/bin/bash
i="$1"

if ! command -v youtube-dl &> /dev/null; then
     echo "youtube-dl未安装，正在安装..."
     sudo pip install youtube-dl >>/dev/null 2>&1 || {
         echo "安装youtube-dl失败，请手动安装: sudo pip install youtube-dl"
         exit 1
     }
fi

name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//')

youtube-dl -o "$name.%(ext)s" "$i" --merge-output-format mp4 --external-downloader aria2c --external-downloader-args "-x10"
echo "$name"
