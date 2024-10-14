#!/bin/bash

#Define logfile
LOGFILE="/tmp/friendly_system_update.sh"

#Check if the user is root
if [[ $EUID -ne 0 ]]; then
echo "You need to run this script with sudo."
exit 1
fi

#Update package list
echo "Updating package list..."
apt update >> "$LOGFILE" 2>&1
if [[ $? -ne 0 ]]; then
echo "apt update failed. Check the log for details."
exit 1
fi

#Count upgradable packages
UPGRADABLE_PACKAGES=$(apt list --upgradable 2>> "$LOGFILE" | grep -c "upgradable")
echo "THere are $UPGRADABLE_PACKAGES packages that require updating."

#Ask user if they want to proceed
read -p "Do you want to proceed with the upgrade? (y/n) " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
echo "Upgrade cancelled."
exit 0
fi

#Display free space before upgrade
FREE_SPACE_BEFORE=$( df -h / | awk 'NR==2 {print $4')
echo "Free space in root filesystems before upgrade: $FREE_SPACE_BEFORE"

#Run upgrade
echo "Upgrading packages..."
apt upgrade -y >> "$LOGFILE" 2>&1
if [[ $? -ne 0 ]]; then
echo "apt upgrade failed. Check the log for details."
exit 1
fi

#Display free space after upgrade
FREE_SPACE_AFTER=$( df -h / | awk 'NR==2 {print $4}')
echo "Free space in root filesystems after upgrade: $FREE_SPACE_AFTER"

echo "Upgrade completed successfully."
