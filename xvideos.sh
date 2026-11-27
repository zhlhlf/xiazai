#!/bin/bash
# 下载单个 xvideos 视频，自动选最高画质；带限流重试、低清延迟重试、失败重试。
# 用法：. xvideos.sh <video-url>
# 环境变量：XVCOOKIE=登录 Cookie（可选）；XIAZAI_ALLOW_LOW=1 允许直接落低清。

if command -v install_if_missing >/dev/null 2>&1; then install_if_missing ffmpeg; fi

i="$1"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
CK=()
[ -n "${XVCOOKIE:-}" ] && CK=(-H "Cookie: $XVCOOKIE")
ATTEMPTS=${PAGE_ATTEMPTS:-5}
BASE_SLEEP=${PAGE_SLEEP_BASE:-5}

page=""; hls=""; high=""; low=""; author=""; title=""; doctitle=""; http_code=""

parse_vars() { # $1=body
    hls=$(printf '%s' "$1"  | grep -oE "setVideoHLS\('[^']*'"      | head -n1 | cut -d"'" -f2)
    high=$(printf '%s' "$1" | grep -oE "setVideoUrlHigh\('[^']*'" | head -n1 | cut -d"'" -f2)
    low=$(printf '%s' "$1"  | grep -oE "setVideoUrlLow\('[^']*'"  | head -n1 | cut -d"'" -f2)
    author=$(printf '%s' "$1" | grep -oE "setUploaderName\('[^']*'" | head -n1 | cut -d"'" -f2)
    title=$(printf '%s' "$1"  | grep -oE "setVideoTitle\('[^']*'"  | head -n1 | cut -d"'" -f2)
    doctitle=$(printf '%s' "$1" | grep -oE '<title>[^<]*' | head -n1 | sed 's/<title>//')
}

is_gone() { # $1=body
    if [ "$http_code" = "404" ] || [ "$http_code" = "410" ]; then return 0; fi
    printf '%s' "$1" | grep -qiE '<title>[^<]*(not found|404|找不到|見つかりません|no encontrado|nicht gefunden|non trouv|не найдено|찾을 수 없)'
}

fetch_page() { # $1=url $2=with_cookie(1/0)
    local tmp; tmp=$(mktemp)
    if [ "$2" = "1" ] && [ "${#CK[@]}" -gt 0 ]; then
        http_code=$(curl -sL --compressed -A "$UA" "${CK[@]}" -H "Accept-Language: en-US,en;q=0.9" -e "https://www.xvideos.com/" -o "$tmp" -w '%{http_code}' "$1")
    else
        http_code=$(curl -sL --compressed -A "$UA" -H "Accept-Language: en-US,en;q=0.9" -e "https://www.xvideos.com/" -o "$tmp" -w '%{http_code}' "$1")
    fi
    page=$(cat "$tmp" 2>/dev/null); rm -f "$tmp"
}

for attempt in $(seq 1 "$ATTEMPTS"); do
    fetch_page "$i" 1
    parse_vars "$page"
    if is_gone "$page"; then
        # Cookie 里的 session token 失效/被轮换时，xvideos 会回 404；改用匿名再试一次
        if [ "${#CK[@]}" -gt 0 ]; then
            echo "  带 Cookie 返回 404（token 可能已失效），改用匿名重试..." >&2
            fetch_page "$i" 0
            parse_vars "$page"
        fi
    fi
    if is_gone "$page"; then
        echo "  视频不存在或已下架（HTTP $http_code, $doctitle），跳过：$i" >&2
        echo "$i" >> gone.txt
        return 0
    fi
    [ -n "$hls" ] && break
    if [ "$attempt" -lt "$ATTEMPTS" ]; then
        d=$((attempt * BASE_SLEEP))
        echo "  没拿到 HLS 地址（第 $attempt/$ATTEMPTS 次，页面 ${#page} 字节），${d}s 后重试..." >&2
        sleep "$d"
    fi
done

name="$author - $title"
# 文件名里的 / \ : * ? " < > | 一律替换，避免 ffmpeg 写文件失败
name=$(printf '%s' "$name" | tr '/\\:*?"<>|' '_________' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')

src=""; tier=""
if [ -n "$hls" ]; then
    master=""
    for m in 1 2 3; do
        if [ "${#CK[@]}" -gt 0 ]; then
            master=$(curl -sL --compressed -A "$UA" "${CK[@]}" "$hls")
        else
            master=$(curl -sL --compressed -A "$UA" "$hls")
        fi
        if printf '%s' "$master" | grep -qE 'hls-[0-9]+p|#EXTINF'; then break; fi
        [ "$m" -lt 3 ] && sleep 3
    done
    # 从 master playlist 里挑分辨率最高的分片（按 -Np 的数字排序，取最大）
    best=$(printf '%s\n' "$master" \
        | grep -oE 'hls-[0-9]+p[^"'"'"'[:space:]]*\.m3u8' \
        | sort -u -t- -k2 -n | tail -n1)
    if [ -n "$best" ]; then
        src="$(dirname "$hls")/$best"
        tier="hd"
        q=${best#hls-}; q=${q%%-*}
        echo "  最高画质：$q"
    elif printf '%s' "$master" | grep -q '#EXTINF'; then
        src="$hls"
        tier="hd"
        echo "  最高画质：HLS(单码率)"
    fi
fi

# HLS 拿不到时只剩 mp4_sd（UrlHigh 与 UrlLow 实际是同一个低清文件）。
# 这种情况不立刻落低清：先记下来，整轮跑完延迟后再重试一次，避免被限流时批量降级。
mp4="${high:-$low}"
if [ -z "$src" ] && [ -n "$mp4" ]; then
    if [ "${XIAZAI_ALLOW_LOW:-0}" = "1" ]; then
        src="$mp4"; tier="low"
        echo "  最高画质：MP4(low)（重试用尽，仍只有低清）"
    else
        echo "  暂时只有低清，记入待重试：$i" >&2
        echo "$i" >> lowq.txt
        return 0
    fi
fi
if [ -z "$src" ]; then
    echo "  没解析到可下载地址（HTTP $http_code，页面 ${#page} 字节，title=$doctitle），记入失败重试：$i" >&2
    echo "$i" >> failed.txt
    return 0
fi

echo "  下载链接：$src"
echo "  $name"

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
rc=$?

# 校验产物：失败/空文件/过小（多半是被 403 或半截流）都清掉并记重试
size=0
[ -f "$out" ] && size=$(stat -c%s "$out" 2>/dev/null || echo 0)
if [ "$rc" -ne 0 ] || [ "$size" -lt 204800 ]; then
    rm -f "$out"
    echo "  下载失败（rc=$rc size=$size），记入失败重试：$i" >&2
    echo "$i" >> failed.txt
    return 0
fi
echo "  完成：$out ($((size/1024/1024))M, $tier)"
