echo 'Please input the war dir'
read war_dir
grep -ra "/psb/data" $war_dir | awk -F: '{print $1}' | uniq > /tmp/psb_log_dir.txt 
cat /tmp/psb_log_dir.txt
echo 'Please input the target dir'
read target_dir_tmp
target_dir=$(echo $target_dir_tmp | sed 's/\//\\\//g')
for i in `cat /tmp/psb_log_dir.txt`;
do
	sed -i "s/\/psb\/data/$target_dir/g" $i
done
echo 'Already change dir'
