#!/bin/bash

#Define logfile
LOGFILE="/tmp/measuring_internet_responsiveness.sh"

#Download the list of hosts
echo "Downloading the list of hosts..."
curl -s https://zonzorp.net/gc/hosts-to-ping.txt -o hosts-to-ping.txt

#Initialize variables for reporting
total_time=0
responded_count=0
non_responded_hosts=()

#Loop through each host and measure response time
while read -r host; do
if [[ -n "$host" ]]; then
{time curl -s "$host" >/dev/null; } 2>> "$LOGFILE"
response_code=$?

if [[ $response_code -eq 0 ]]; then
real_time=$(grep "real" "$LOGFILE" | tail -n 1 | awk '{print $2}')
total_time=$(echo "$total_time + $real_time" | bc)
responded_count=$((responded_count + 1))
else
non_responded_hosts+=("host")
fi
fi

done < host-to-ping.txt

#Calculate average response time
if [[ $responded_count -gt 0 ]]; then
average_time=$(echo "scale=2; $total_time / $responded_count" | bc)
echo "Average response time for responding hosts: $average_time seconds."
else
echo "No hosts responded"
fi

#Report non-responded hosts
if [[ $(#non_responded_hosts[@]} -gt 0 ]]; then
echo "The following hosts did not respond:"
for host in "${non_responded_hosts[@]}"; do
echo "$host"
done
else
echo "All hosts responded successfully."
fi
