#!/bin/bash

# Function to log error and exit if something goes wrong
log_error_and_exit() {
  echo "$1"
  exit 1
}

# Default value for verbose mode
verbose=0

# Parse command line arguments for verbose mode
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -verbose)
      verbose=1
      shift
      ;;
    *)
      log_error_and_exit "Unknown option: $1"
      ;;
  esac
done

# Check if configure-host.sh exists in the current directory
if [ ! -f ./configure-host.sh ]; then
  log_error_and_exit "configure-host.sh script not found in the current directory."
fi

# Define server details
server1="remoteadmin@server1-mgmt"
server2="remoteadmin@server2-mgmt"

# Transfer the configure-host.sh script to server1
echo "Transferring configure-host.sh to $server1..."
scp ./configure-host.sh "$server1:/root" || log_error_and_exit "Failed to transfer configure-host.sh to $server1."

# Run configure-host.sh on server1 with the desired configurations
echo "Running configure-host.sh on $server1..."
ssh "$server1" "bash /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4 ${verbose:+-verbose}" || log_error_and_exit "Failed to run configure-host.sh on $server1."

# Transfer the configure-host.sh script to server2
echo "Transferring configure-host.sh to $server2..."
scp ./configure-host.sh "$server2:/root" || log_error_and_exit "Failed to transfer configure-host.sh to $server2."

# Run configure-host.sh on server2 with the desired configurations
echo "Running configure-host.sh on $server2..."
ssh "$server2" "bash /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3 ${verbose:+-verbose}" || log_error_and_exit "Failed to run configure-host.sh on $server2."

# Run configure-host.sh locally on the desktop VM to update /etc/hosts
echo "Updating local /etc/hosts file..."
./configure-host.sh -hostentry loghost 192.168.16.3 || log_error_and_exit "Failed to update /etc/hosts with loghost entry."
./configure-host.sh -hostentry webhost 192.168.16.4 || log_error_and_exit "Failed to update /etc/hosts with webhost entry."

echo "All configurations applied successfully!"
