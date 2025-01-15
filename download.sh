#!/bin/bash


asd(){
    while true;do
        echo > a.log
        sleep 6
        tail -n2 a.log
    done
}

asd &
pid=$!
   
for i in $1;do
    if [ `echo "$i" | grep "google.com/download"` ];then
        rm -rf dGoogleUrl.sh; wget -q https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/dGoogleUrl.sh ; chmod 777 * -R
        i=`./dGoogleUrl.sh "$i"`
        echo $i
    elif [ `echo "$i" | grep "pornhub.com"` ];then
        ./d_pronhub.sh "$i"
        continue
    fi
    echo "UA: $3"
    aria2c -x$2 -U "$3" "$i" -d 666 > a.log

done

kill -8 $pid
