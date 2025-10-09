#!/bin/bash

m=$(ls 666)
for i in $m; do
    if [[ $(du -sb 666/$i | awk '{print $1}') -gt 2097152000 ]];then
      echo -e "split packaging..." 
      split -d -b 2048m "666/$i" "666/$i"
      rm -rf "666/$i"
    fi    
done