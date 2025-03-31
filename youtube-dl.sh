#!/bin/bash
i="$1"

sudo pip install youtube-dl >>/dev/null

mode="$2"  # 第二个参数是模式

if [ "$mode" = "0" ]; then
    # 获取名字
    name=$(curl -sL "$i" | grep inlineFree | cut -d'>' -f 2 | cut -d'<' -f 1)
    
    # 可选的 name 限制（如果需要）
    # name=$(echo "$name" | perl -CSD -pe 's/[^\x{4E00}-\x{9FFF}\x{3040}-\x{309F}\x{30A0}-\x{30FF}a-zA-Z0-9 ]//g')
    # name="${name:0:60}"

    # 使用获取的名字下载
    youtube-dl -o "$name.%(ext)s" "$i" --external-downloader aria2c --external-downloader-args "-x10"
    echo "$name"

elif [ "$mode" = "1" ]; then
    # 使用 youtube-dl 的默认标题下载
    youtube-dl -o "%(title)s.%(ext)s" "$i" --external-downloader aria2c --external-downloader-args "-x10"
fi