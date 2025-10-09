#!/bin/bash

echo ${1}
url1="${1}?page="

echo >b.txt
i=1
filename=""
mkdir -p tmp
echo > b.txt
while true; do
	url="${url1}$i"
	curl -sL $url >b
	if [ ! "$filename" ];then
		s=`cat b | grep -n "h1 itemprop=" | cut -d\: -f1`
		let s=s+1
		filename=`cat b | sed -n ${s}p | cut -d\< -f1 | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'`
		echo "影片作者: $filename"
	fi
	if grep -q "查找失败" b; then
		break
	fi
	toline=`cat b | grep showMoreLess -n | cut -d\: -f1`
	sed -i "1,${toline}d" b
	cat b | grep "data-video-vkey=" | cut -d\" -f2 | uniq | sed 's/^/https:\/\/cn.pornhub.com\/view_video.php?viewkey=/' >> b.txt

	echo "page: $i"

	let i=i+1
done
rm -rf b

mv b.txt "tmp/$filename.txt"
