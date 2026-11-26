#!/bin/bash
# 下载单个 xvideos 视频，自动选最高画质，带重试与同名去重。
# 用法：. xvideos.sh <video-url>

if command -v install_if_missing >/dev/null 2>&1; then install_if_missing ffmpeg; fi

i="$1"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

page=""; hls=""; high=""; low=""; author=""; title=""

# 取视频页并解析播放器变量。若只拿到 low（xvideos 限流时会降级成仅低清），重试。
for attempt in 1 2 3; do
    page=$(curl -sL --compressed -A "$UA" \
        -H "Accept-Language: en-US,en;q=0.9" \
        -e "https://www.xvideos.com/" "$i")
    hls=$(printf '%s' "$page"  | grep -oE "setVideoHLS\('[^']*'"      | head -n1 | cut -d"'" -f2)
    high=$(printf '%s' "$page" | grep -oE "setVideoUrlHigh\('[^']*'" | head -n1 | cut -d"'" -f2)
    low=$(printf '%s' "$page"  | grep -oE "setVideoUrlLow\('[^']*'"  | head -n1 | cut -d"'" -f2)
    author=$(printf '%s' "$page" | grep -oE "setUploaderName\('[^']*'" | head -n1 | cut -d"'" -f2)
    title=$(printf '%s' "$page"  | grep -oE "setVideoTitle\('[^']*'"  | head -n1 | cut -d"'" -f2)
    if [ -n "$hls" ] || [ -n "$high" ]; then
        break
    fi
    if [ "$attempt" -lt 3 ]; then
        echo "没拿到高清地址（第 $attempt 次，页面 ${#page} 字节），${attempt}0 秒后重试..." >&2
        sleep $((attempt * 5))
    fi
done

name="$author - $title"
# 文件名里的 / \ : * ? " < > | 一律替换，避免 ffmpeg 写文件失败
name=$(printf '%s' "$name" | tr '/\\:*?"<>|' '_________' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')

src=""
if [ -n "$hls" ]; then
    master=""
    for m in 1 2 3; do
        master=$(curl -sL --compressed -A "$UA" "$hls")
        if printf '%s' "$master" | grep -qE 'hls-[0-9]+p|#EXTINF'; then break; fi
        [ "$m" -lt 3 ] && sleep 3
    done
    # 从 master playlist 里挑分辨率最高的分片（按 -Np 的数字排序，取最大）
    best=$(printf '%s\n' "$master" \
        | grep -oE 'hls-[0-9]+p[^"'"'"'[:space:]]*\.m3u8' \
        | sort -u -t- -k2 -n | tail -n1)
    if [ -n "$best" ]; then
        src="$(dirname "$hls")/$best"
        q=${best#hls-}; q=${q%%-*}
        echo "最高画质：$q"
    elif printf '%s' "$master" | grep -q '#EXTINF'; then
        # setVideoHLS 本身就是媒体列表
        src="$hls"
        echo "最高画质：HLS(单码率)"
    fi
fi
# HLS 拿不到时退回最高码率 MP4
if [ -z "$src" ] && [ -n "$high" ]; then
    src="$high"
    echo "最高画质：MP4(high)"
fi
if [ -z "$src" ] && [ -n "$low" ]; then
    src="$low"
    echo "最高画质：MP4(low)（重试后仍无更高码率，可能被限流）"
fi

echo "下载链接：$src"
echo "$name"
[ -z "$src" ] && { echo "错误：没解析到可下载地址"; return 1 2>/dev/null || exit 1; }

# 同名视频（比如多个「验证视频」）会互相覆盖，用视频 id 做后缀区分
id=$(printf '%s' "$i" | awk -F/ '{print $(NF-1)}')
[ -z "$id" ] && id=$(printf '%s' "$i" | md5sum | cut -c1-8)
[ -z "$name" ] || [ "$name" = " - " ] && name="$author - $id"
out="$name.mp4"
[ -e "$out" ] && out="$name-$id.mp4"
[ -e "$out" ] && out="$name-$id-$(date +%s%N).mp4"

ffmpeg -y -loglevel error -threads "$(nproc)" -i "$src" \
    -c:v copy -c:a copy \
    -movflags +faststart \
    "$out"
