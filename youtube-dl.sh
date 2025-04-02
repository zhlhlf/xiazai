#!/bin/bash
# YouTube视频下载并转换为MP4格式脚本
# 使用方法: ./script.sh "YouTube_URL"

i="$1"

# 检查youtube-dl是否安装
if ! command -v youtube-dl &> /dev/null; then
    echo "youtube-dl未安装，正在安装..."
    sudo pip install youtube-dl >>/dev/null 2>&1 || {
        echo "安装youtube-dl失败，请手动安装: sudo pip install youtube-dl"
        exit 1
    }
fi

# 检查aria2c是否安装
if ! command -v aria2c &> /dev/null; then
    echo "aria2c未安装，正在安装..."
    sudo apt-get install -y aria2 >>/dev/null 2>&1 || {
        echo "安装aria2c失败，请手动安装: sudo apt-get install aria2"
        exit 1
    }
fi

# 获取视频标题作为文件名
name=$(curl -sL "$i" | grep '<title>' | cut -d\> -f 2 | awk -F- '{for(i=1;i<NF;i++) printf "%s%s", $i, (i==NF-1?"":FS)}')
name=$(echo "$name" | sed 's#/#-#g' | sed 's/[[:space:]]*$//' | tr -d '\n')

echo "正在下载视频: $name"

# 使用youtube-dl下载视频(TS格式)
youtube-dl -o "$name.ts" "$i" --external-downloader aria2c --external-downloader-args "-x10" || {
    echo "视频下载失败"
    exit 1
}

# 检查ffmpeg是否安装
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg未安装，正在安装..."
    sudo apt-get update && sudo apt-get install -y ffmpeg xvfb >>/dev/null 2>&1 || {
        echo "安装ffmpeg失败，请手动安装: sudo apt-get install ffmpeg xvfb"
        exit 1
    }
fi

# 转换为MP4格式
echo "正在将 $name.ts 转换为MP4格式..."
xvfb-run -a ffmpeg -nostdin -loglevel error -i "$name.ts" -c:v copy -c:a copy "$name.mp4" || {
    echo "视频转换失败"
    exit 1
}

# 检查转换是否成功
if [ -f "$name.mp4" ]; then
    echo "转换成功！清理临时文件..."
    rm -f "$name.ts"
    echo "最终文件: $name.mp4"
else
    echo "转换失败，保留原始文件 $name.ts"
    exit 1
fi
