list=$(find 666/*)
i=1
while true
do
tt=$(sed -n ${i}p <<end
$list
end
)
i=$(($i+1))
if [ ! "$tt" ];then
    break
fi
./transfer $1 "$tt"
done
