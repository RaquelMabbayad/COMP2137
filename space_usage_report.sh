#!/bin/bash

#Check if the user is root
if [[ $EUID -ne 0 ]]; then
echo "You need to run this script with sudo."
exit 1
fi

#Check free space in the root filesystem
FREE_SPACE=$(df / | awk 'NR==2 {print $4}')
TOTAL_SPACE=$(df / | awk 'NR==2 {print $2}')
FREE_PERCENTAGE=$((FREE_SPACE * 100 / TOTAL_SPACE))

if [[ $FREE_PERCENTAGE -ge 50 ]]; then
echo "The root filesystem has at least 50% free space."
exit 0
fi

#Display the 20 largest regular files owned by ordinary users
echo "Displaying the 20 largest regular files owned by ordinary users:"
echo "Size (bytes) Owner  Pathname"
echo "------------------------------"

#Find and display the largest files
find / -type f -uid +1000 -printf "%s\t%u\t%p\n" 2>/dev/null | sort -n -r | head -n 20 | awk -F'\t' '{printf "%12d %-12s %s\n", $1, $2, $3}'
