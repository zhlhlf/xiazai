type=$1
rclone_key=$2

if [ $type = "one" ]; then
   curl -sL https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/upload/upload.sh | bash -s $rclone_key tyy2/临时存放文件
elif [ $type = "wet" ];then
   wget https://raw.githubusercontent.com/zhlhlf/text/main/upload-wetransfer.py
   python upload-wetransfer.py 666/*
fi
