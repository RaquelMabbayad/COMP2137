#!/bin/bash

verbose=0
ip_address=""
gateway=""
dns_server=""
search_domains=""

#Display help message
usage() {
	echo "Usage: $0 -i <ip_address> [-g <gateway>] [-d <dns_server>] [-s <search_domains>] [-v] [-h]"
	echo "	-i <ip_address>	IP address in CIDR format (required)"
	echo "	-g <gateway>	Gateway IP address (optional)"
	echo "	-d <dns_server>	DNS Server IP address (optional, defaults to gateway)"
	echo "	-s <search_domains> List of search domains (optional)"
	echo "	-v		Enable verbose output"
	echo "	-h		Display this help message"
	exit 1
}

#Parse command-line options
while getopts ":i:g:d:s:vh" opt; do
	case $opt in
		i)
			ip_address=$OPTARG
			;;
		g)
			gateway=$OPTARG
			;;
		d)
			dns_server=$OPTARG
			;;
		s)
			search_domains=$OPTARG
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

#Check if IP address is provided
if [ -z "$ip_address" ]; then
	echo "IP address is required." >&2
	usage
fi

#Set gateway to DNS if not provided
if [ -z "$dns_server" ] && [ -n "$gateway" ]; then
	dns_server=$gateway
fi

#Apply changes
if [ $verbose -eq 1 ]; then
	echo "Configuration IP address: #ip_address"
	echo "Gateway: $gateway"
	echo "DNS Server: $dns_server"
	echo "Search domains: $search_domains"
fi

#Configure IP address
sudo netplan set network.ethernets.enp0s3.addresses=$ip_address
[ -n "$gateway" ] && sudo netplan set network.ethernets.enp0s3.gateway4=$gateway
[ -n "$dns_server" ] && sudo netplan set network.nameservers.addresses=$dns_server
[ -n "$search_domains" ] && sudo netplan set network.nameservers.search=$search_domains

if [ $verbose -eq 1 ]; then
	echo "Network configuration updated."
fi

#Apply the new network configuration
sudo netplan apply	
