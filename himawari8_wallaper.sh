#!/bin/bash
width=550
level="4d" #Level can be 4d, 8d, 16d, 20d 
numblocks=4 #this apparently corresponds directly with the level, keep this exactly the same as level without the 'd'

time_stamp=$(date +'%Y%m%d%H%M%S')
short_time_stamp=$(date +'%H%M%S')

#get lastest.json with information about last photo
latest_info_url="http://himawari8-dl.nict.go.jp/himawari8/img/D531106/latest.json"
#extract from json date and time
date_time_photo_str=`curl $latest_info_url |grep -Eo '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2} [[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}' `
#extract from json time
time_photo_str=`echo $date_time_photo_str |grep -Eo '[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}' `

#debug info
echo "Time photo: $time_photo_str"
echo "The last photo was took: $date_time_photo_str"

#convert date_time_photo_str to url format
#example: from 2016-02-09 22:40:00 to 2016/02/09/224000 
date_time_url=`echo $date_time_photo_str | sed 's/[- ]/\//g' | sed 's/[:]//g'`
#convert date_time_photo_str to url format
#example: from 22:40:00 224000 
time_url=`echo $time_photo_str | sed 's/[:]//g'`

#url with parameters to photo 
base_url="http://himawari8-dl.nict.go.jp/himawari8/img/D531106/$level/$width/$date_time_url"
#temporary folder for save parts of photo
tmp_folder="$HOME/tmp$time_stamp"

echo $tmp_folder

file_ext=".png"
outfile="result_$time_stamp$file_ext"

echo "Outfile: $outfile"

current_path=$(pwd)

cd ~/Pictures/
mkdir -p Himawari8 || exit
cd $current_path

wallaper_path="$HOME/Pictures/Himawari8/"


mkdir $tmp_folder
cd $tmp_folder

count=0
for ((i=0; i < $numblocks; i++))
do
	for ((j=0; j < $numblocks; j++))
	do
	   	real_url=$base_url"_"$i"_"$j$file_ext
	   	echo "Real url: $real_url"
  		wget -i -P -q $real_url
   		echo "Download to: $tmp_folder"
   		file_name=$short_time_stamp"_"$j"_"$i$file_ext
   		echo "Image name: $file_name"
	done
done	


count=0

output_fileset_str=""
result_fileset_str=""

for ((i=0; i < $numblocks; i++))
do
	output_fileset_str=""
	for ((j=0; j < $numblocks; j++))
	do
	   	file_name=$tmp_folder/$time_url"_"$i"_"$j$file_ext
	   	output_fileset_str=$output_fileset_str" "$file_name
	done
	echo "Output fileset: $output_fileset_str"
	montage $output_fileset_str -mode Concatenate  -tile 1x4  output$i.png
	result_fileset_str=$result_fileset_str" "output$i.png
done
echo "Result fileset: $result_fileset_str"

echo "Result file: $outfile"
montage $result_fileset_str -mode Concatenate  -tile 4x1  $wallaper_path$outfile


echo "cureent path $current_path"
cd $current_path
rm -rf $tmp_folder

#Number of worspaces
workspace_count=$(xfconf-query -v -c xfwm4 -p /general/workspace_count)
connected_monitor=$(xrandr -q | awk '/ connected/{print $1}')
xfce_desktop_prop_prefix=/backdrop/screen0/monitor$connected_monitor

echo "Wallaper path: $wallaper_path"
echo "Outfile: $outfile"

#Set wallaper for all worspaces(only for XFCE)
for ((i=1; i <= $workspace_count; i++))
do
   xfconf-query -c xfce4-desktop -p $xfce_desktop_prop_prefix/workspace$i/last-image -s $wallaper_path$outfile
   xfconf-query -c xfce4-desktop -p $xfce_desktop_prop_prefix/workspace$i/image-style -s 5
   echo "Set $wallaper_path$outfile for workspace $i"
done


