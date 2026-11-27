#!/bin/bash
# 收集某个 xvideos 账号/频道下的全部视频链接到 tmp/<author>.txt
# 支持：https://www.xvideos.com/<author>
#       https://www.xvideos.com/channels/<author>/...
#       https://www.xvideos.com/profiles/<author>/...
#       https://www.xvideos.com/amateur-channels/<author>/...

mkdir -p tmp

i="${1%%\?*}"          # 去掉 query
i="${i%/}"             # 去掉末尾斜杠

path=$(echo "$i" | sed -E 's#^https?://[^/]+/##; s#[/?].*$##; s#/$##')
case "$path" in
    */*) author=$(echo "$path" | awk -F/ '{print $2}') ;;
    *)   author="$path" ;;
esac
echo "Author: $author"

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
out="tmp/$author.txt"
: > "$out"

CK=()
[ -n "${XVCOOKIE:-}" ] && CK=(-H "Cookie: $XVCOOKIE")

http_code=""
fetch() { # $1=url $2=nocookie
    local tmp; tmp=$(mktemp)
    if [ "$2" = "nocookie" ] || [ "${#CK[@]}" -eq 0 ]; then
        http_code=$(curl -sL --compressed \
            -A "$UA" \
            -H "Accept: application/json,text/plain,*/*" \
            -H "Referer: https://www.xvideos.com/$author" \
            -o "$tmp" -w '%{http_code}' "$1")
    else
        http_code=$(curl -sL --compressed \
            -A "$UA" "${CK[@]}" \
            -H "Accept: application/json,text/plain,*/*" \
            -H "Referer: https://www.xvideos.com/$author" \
            -o "$tmp" -w '%{http_code}' "$1")
    fi
    body=$(cat "$tmp" 2>/dev/null); rm -f "$tmp"
}

# 把一页响应解析成视频路径（每行一个）。优先按官方 JSON 的 .videos[].u，
# 兼容 .videos 为 null / 顶层为 null 的情况；若返回的是 HTML 则从页面里抓链接。
parse_page() { # $1=body
    local body="$1" urls
    urls=$(printf '%s' "$body" | jq -r '(.videos // [])[]? | (.u // empty)' 2>/dev/null)
    if [ -z "$urls" ] && ! printf '%s' "$body" | jq -e . >/dev/null 2>&1; then
        # HTML 兜底：抓 /video.xxx/... 与 /prof-video-click/...
        urls=$(printf '%s' "$body" \
            | grep -oE '/(video\.[A-Za-z0-9]+/[^"'"'"'<> ]*|prof-video-click/upload/[^"'"'"'<> ]*)' \
            | sed 's/&amp;/\&/g' | sort -u)
    fi
    printf '%s\n' "$urls" | grep -v '^$'
}

num=0
empty_retry=0
total=""
got=0
while [ "$num" -lt 300 ]; do
    echo "Page: $num"
    fetch "https://www.xvideos.com/channels/$author/videos/best/$num"
    if [ "$http_code" = "404" ] && [ "${#CK[@]}" -gt 0 ]; then
        fetch "https://www.xvideos.com/channels/$author/videos/best/$num" nocookie
    fi
    list=$(parse_page "$body")

    if [ "$num" -eq 0 ] && [ -z "$total" ]; then
        total=$(printf '%s' "$body" | jq -r '.nb_videos // empty' 2>/dev/null)
        [ -n "$total" ] && echo "该账号共 $total 个视频"
    fi

    if [ -z "$list" ]; then
        # 可能是真的到底（末尾页返回 {"result":false,"code":404}），也可能是被限流挡了一下：重试一次再判定
        if [ "$empty_retry" -eq 0 ]; then
            empty_retry=1
            sleep 3
            fetch "https://www.xvideos.com/channels/$author/videos/best/$num"
            list=$(parse_page "$body")
        fi
        [ -z "$list" ] && break
    fi

    cnt=0
    while IFS= read -r u; do
        [ -z "$u" ] && continue
        case "$u" in
            http*) printf '%s\n' "$u" ;;
            /*)    printf 'https://www.xvideos.com%s\n' "$u" ;;
            *)     printf 'https://www.xvideos.com/%s\n' "$u" ;;
        esac
        cnt=$((cnt + 1))
    done <<< "$list" >> "$out"

    got=$((got + cnt))
    num=$((num + 1))
    # 已知总数就按总数停；否则不足一整页（10 条）就当最后一页
    if [ -n "$total" ] && [ "$got" -ge "$total" ]; then
        break
    fi
    if [ "$cnt" -lt 10 ]; then
        break
    fi
done

sort -u "$out" -o "$out" 2>/dev/null
echo "Total: $(grep -c . "$out") -> $out"
