#!/bin/bash
export logfile="$(pwd)/dl.log"
touch $logfile

if [ ! -d 666 ]; then
    mkdir -p 666
fi

. utils.sh

ROOT=$(pwd)
cd 666

# 新一轮开始时清掉上一轮的待重试清单（重试轮不清）
if [ "${XIAZAI_RETRY:-0}" != "1" ]; then
    rm -f lowq.txt failed.txt gone.txt retried.flag
fi


current=0
total_params=$(echo "$1" | wc -w)

for i in $1; do

    ((current++))
    echo "Processing item $current/$total_params: $i"
    
    if [ $(echo "$i" | grep "google.com/download") ]; then
        rm -rf dGoogleUrl.sh
        wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh
        chmod 777 * -R
        i=$(. dGoogleUrl.sh "$i")
        echo $i
    elif [ $(echo "$i" | grep "https://cn.pornhub.com/model/") ]; then
        . ../pornhub_getUserAllVides.sh "$i"
        u_list=$(cat tmp/*.txt 2>/dev/null)
        rm -rf tmp
        [ -n "$u_list" ] && ( cd "$ROOT" && . ./download.sh "$u_list" )
        continue
    elif [ $(echo "$i" | grep -E "pornhub.com|youtube.com") ]; then
        . ../pornhub.sh "$i"
        continue
    elif [ $(echo "$i" | grep -E "www\.xvideos\.com/(prof-video-click|video[./])") ]; then
        . ../xvideos.sh "$i"
        continue
    elif [ $(echo "$i" | grep "www.xvideos.com") ]; then
        . ../xvideos_getUserAllVides.sh "$i"
        u_list=$(cat tmp/*.txt 2>/dev/null)
        rm -rf tmp
        # 子 shell 里回仓库根目录再跑，避免把当前 cwd 留在 666 里导致后面 cd 666 失败
        [ -n "$u_list" ] && ( cd "$ROOT" && . ./download.sh "$u_list" )
        continue
    elif [ ${i: -5} == ".m3u8" ]; then
        install_if_missing ffmpeg
        echo "Downloading m3u8 video: $i"
        ffmpeg -i "$i" -c copy "temp.mp4"
        echo "Optimizing video for web playback..."
        ffmpeg -i "temp.mp4" -c copy -movflags +faststart "final.mp4"
        mv "final.mp4" "$(md5sum "final.mp4" | awk '{ print $1 }').mp4"
        rm -rf temp.mp4 index.m3u8
        continue
    fi
    echo "aria2c  UA: $3"
    aria2c -x$2 -U "$3" "$i" 

done

# 已下架/404 的单独统计（不再重试）
if [ -s gone.txt ]; then
    echo "=== 跳过 $(grep -c . gone.txt) 个已下架/404 视频 ==="
fi

# 一轮结束后，对「只有低清」和「彻底失败」的链接延迟重试一次（只重试一遍）
if [ "${XIAZAI_RETRY:-0}" != "1" ] && [ ! -f retried.flag ]; then
    retry_urls=$(cat lowq.txt failed.txt 2>/dev/null | awk 'NF' | sort -u | tr '\n' ' ')
    if [ -n "$retry_urls" ]; then
        cnt=$(printf '%s' "$retry_urls" | wc -w)
        echo "=== 延迟 ${RETRY_WAIT:-45}s 后重试 $cnt 个（低清/失败） ==="
        sleep "${RETRY_WAIT:-45}"
        touch retried.flag
        rm -f lowq.txt failed.txt
        ( cd "$ROOT" && XIAZAI_RETRY=1 XIAZAI_ALLOW_LOW=1 ./download.sh "$retry_urls" "$2" "$3" )
    fi
fi

wait
rm -rf $logfile
