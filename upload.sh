type=$1
rclone_key=$2

if [ $type = "one" ]; then
   wget -q https://raw.github.com/zhlhlf/text/main/onedrive_mount.sh && sh onedrive_mount.sh $rclone_key 临时存放文件         
elif [ $type = "wet" ];then
   wget https://raw.githubusercontent.com/zhlhlf/text/main/upload-wetransfer.py
   python upload-wetransfer.py 666/*
fi