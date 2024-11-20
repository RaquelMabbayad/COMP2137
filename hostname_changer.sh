#!/bin/bash

verbose-0
hostname=""

#Display help message
usage() {
	echo "Usage: $0 -n <hostname> [-v] [-h]"
	echo "	-n <hostname> Set the system hostname"
	echo " 	-v 	      Enable verbose output"
	echo "	-h	      Display this help message"
	exit 1
}

#Parse command-line options
while getopts ":n:vh" opt; do
	case $opt in
		n)
			hostname=$OPTARG
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

#Check if hostname is provided
if [ -z "$hostname" ]; then
	echo "Hostname is required." >&2
	usage
fi

#Change hostname
if [ $verbose -eq 1 ]; then
	echo "Changing hostname to $hostname..."
fi
sudo hostnamectl set-hostname $hostname

#Update /etc/hosts
if [$verbose -eq 1 ]; then
	echo "Updating /etc/hosts..."
fi
sudo sed -i "s/127.0.0.1.*/127.0.0.1 $hostname localhost/" /etc/hosts

if [ $verbose -eq 1 ]; then
	echo "Hostname changed to $hostname and /etc/hosts updated."
fi
