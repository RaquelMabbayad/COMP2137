#!/bin/bash

#Hardware Summary Report Function
hardware_summary_report() {
	echo "Hardware Summary Report:"
	echo "========================="

	#Network Interface Names
	echo "Network Interfaces:"
	ip -o link show | awk -F' : ' '{print $2}'
	echo

	#Processor model name, Number of cores, and speed
	echo "Processor Information:"
	grep -m 1 "model name" /proc/cpuinfo | sed 's/model name\t: //'
	echo "Cores: $(grep -c "^processor" /proc/cpuinfo)"
	grep -m 1 "cpu MHz" /proc/cpuinfo | awk '{print "Speed: " $4 " MHz"}'
	echo

	#Memory size and manufacturer identification
	echo "Memory Information:"
	dmidecode --type memory | grep -E 'Size:|Manufacturer:|Part Number:'
	echo

	#Disk drive device names and model names
	echo "Disk Drives:"
	lsblk -d -o NAME,MODEL
	echo

	#Video card model name
	echo "Video Card Information:"
	lspci | grep -i 'vga\|3d\|2d'
	echo
}

#Storage management report function
storage_management_report() {
	echo "Storage Management Report:"
	echo "==========================="

	#Local disk filesystems - device names and mount points
	echo "Mounted Local Disk Filesystems:"
	df -hT | awk '$2 != "tmpfs" && $2 != "devtmpfs" {print "Device: "$1", Type: "$2", Mounted on: "$7}'
	echo

	#Mounted network filesystems - network source and mount points
	echo "Mounted Network Filesystems:"
	df -hT | awk '$2 == "nfs" || $2 == "cifs" {print "Network Source: "$1", Mounted on: "$7}'
	echo

	#Free space available in the filesystems holding home directory
	echo "Free Space in Home Directory Filesystems:"
	df -h ~ | awk 'NR==2 {print "Filesystem: "$1", Free Space: "$4}'
	echo

	#Space used and number of files in a specified directory
	echo "Space and File Count in Home Directory:"
	du -sh ~ | awk '{print "Total Space Used: "$1}'
	find ~ -type f | wc -l | awk '{print "Total Files: "$1}'
	echo
}

#Network configuration information report function
network_configuration_report() {
	echo "Network Configuration Report:"
	echo "============================="

	#Primary LAN Interface, IP Address, and Subnet Mask
	primary_interface=$(ip route | grep default | awk '{print $5}')
	primary_ip_info=$(ip -4 addr show $primary_interface | grep "inet " | awk '{print $2}')
	echo "Primary LAN Interface: $primary_interface"
	echo "IP Address and Subnet Mask: $primary_ip_info"
	echo

	#Hostname and LAN IP Matching Check
	lan_ip=$(echo $primary_ip_info | cut -d/ -f1)
	hostname=$(hostname)
	lan_ip_hostname=$(getent hosts $lan_ip | awk '{print $2}')
	hostname_ip=$(getent hosts $hostname | awk '{print $1}')
	echo "Hostname associated with LAN IP: $lan_ip_hostname"
	echo "Current Hostname IP Address: $hostname_ip"
	echo "Do they match? $( "[$lan_ip" = "$hostname_ip" ] && echo "Yes" || echo "No")"
	echo

	#Gateway router IP address
	gateway_ip=$(ip route | grep default | awk '{print $3}')
	echo "Gateway Router IP Address: $gateway_ip"
	echo

	#Public IP Address
	public_ip=$(curl -s ifconfig.me)
	echo "PUblic IP Address: $public_ip"
	echo
} 

#Main script with dialog menu
show_menu() {
	dialog --clear --backtitle "System Report Menu" --title "Choose Report" \
	--menu "Select a report to run:" 15 50 3 \
	1 "Network Configuration Report" \
	2 "Hardware Summary Report" \
	3 "Storage Management Report" 2>temp_choice.txt

	choice=$(<temp_choice.txt)
	clear

	case $choice in 
		1) network_configuration_report ;;
		2) hardware_summary_report ;;
		3) storage_management_report ;;
		*) echo "Invalid choice. Existing." ;;
	esac
}

#Run the menu
show_menu

#Clean up
rm -f temp_choice.txt
