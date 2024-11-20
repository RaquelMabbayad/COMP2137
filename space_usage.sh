#!/bin/bash

verbose=0
mount_points="/"
min_free_space=0
min_file_size=0
file_count=10

#Display the help message
usage() {
	echo "Usage: $0 -m <mount_point> -f <min_free_space> -s <min_file_size> -c <file_count> [-v] [-h]"
	echo "	-m <mount_point>	Mount point of filesystems to check"
	echo "	-f <min_free_space>	Minimum free space (in KB) to skip file search"
	echo "	-s <min_file_size>	Minimum size of files to report (in KB)"
	echo "	-c <file_count>		Number of files to include in your report"
	echo "	-v			Enable verbose output"
	echo "	-h			Display this help message"
	exit 1
}

#Parse command-line options
while getopts ":m:f:s:c:vh" opt; do
	case $opt in
		m)
			mount_point=$OPTARG
			;;
		f)
			min_free_space=$OPTARG
			;;
		s)
			min_file_size= $OPTARG
			;;
		c)
			file_count=$OPTARG
			;;
		v)
			verbose=1
			;;
		h)
			usage
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			;;
	esac
done

#Check mount point and free space
if [ $verbose -eq 1 ]; then
	echo "Checking space usage for mount point $mount_point"
fi

#Get free space
free_space=$(df "$mount_point" | awk 'NR==2 {print $4}')

if [ $free_space -lt $min_free_space ]; then
	if [ $verbose -eq 1 ]; then
		echo "Not enough free space. Skipping file search."
	fi
	exit 0
fi

#Get files and report based on size
if [ $verbose -eq 1 ]; then
	echo "Listing files larger than $min_file_size KB..."
fi

find "$mount_point" -type f -size +${min_file_size}k -exec ls -lh {} \; | head -n $file_count

