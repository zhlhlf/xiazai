type_dir=$1
rclone_key=$2

type=`echo $type_dir | awk '{print $1}'`
mount_dir=`echo $type_dir | awk '{print $2}'`

if [ $type = "one" ]; then
   curl -sL https://raw.githubusercontent.com/zhlhlf/text/refs/heads/main/upload/upload.sh | bash -s "$rclone_key" "$mount_dir"
elif [ $type = "wet" ];then
   python upload-wetransfer.py 666/*
fi
