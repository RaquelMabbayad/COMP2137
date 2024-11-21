#!/bin/bash

# Function to log messages
log_message() {
  if [ "$verbose" -eq 1 ]; then
    echo "$1"
  fi
  logger "$1"
}

# Function to handle signal traps
trap '' SIGTERM SIGINT SIGHUP

# Default values
verbose=0
desired_name=""
desired_ip=""
desired_hostentry_name=""
desired_hostentry_ip=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -verbose)
      verbose=1
      shift
      ;;
    -name)
      desired_name="$2"
      shift 2
      ;;
    -ip)
      desired_ip="$2"
      shift 2
      ;;
    -hostentry)
      desired_hostentry_name="$2"
      desired_hostentry_ip="$3"
      shift 3
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Function to change the hostname
change_hostname() {
  local current_name
  current_name=$(hostname)

  if [ "$current_name" != "$desired_name" ]; then
    if [ -n "$desired_name" ]; then
      echo "$desired_name" > /etc/hostname
      hostname "$desired_name"
      log_message "Hostname changed to $desired_name."
    fi
  elif [ "$verbose" -eq 1 ]; then
    log_message "Hostname is already set to $desired_name. No changes needed."
  fi
}

# Function to change IP address
change_ip() {
  local current_ip
  current_ip=$(hostname -I | awk '{print $1}')
  local interface

  # Dynamically detect the primary network interface
  interface=$(ip -4 route show default | grep -oP '(?<=dev )\S+')

  if [ -z "$interface" ]; then
    log_message "Unable to detect the network interface. Exiting."
    exit 1
  fi

  if [ "$current_ip" != "$desired_ip" ]; then
    if [ -n "$desired_ip" ]; then
      # Update the IP address in /etc/hosts
      sed -i "s/$current_ip/$desired_ip/g" /etc/hosts

      # Search for netplan configuration files
      netplan_files=$(find /etc/netplan/ -type f -name "*.yaml")

      if [ -z "$netplan_files" ]; then
        log_message "No netplan configuration files found. IP change failed."
        return
      fi

      # Loop through all netplan files and update the IP address
      for netplan_file in $netplan_files; do
        # Backup the original file before editing
        cp "$netplan_file" "$netplan_file.bak"

        # Update the IP address in the netplan YAML configuration
        if grep -q "dhcp4: true" "$netplan_file"; then
          # For DHCP, we need to modify the static IP settings or change to static
          sed -i "/dhcp4: true/a \\        addresses: [\"$desired_ip/24\"]" "$netplan_file"
          sed -i "/dhcp4: true/d" "$netplan_file"
        elif grep -q "addresses:" "$netplan_file"; then
          # For static IP configurations, update the address
          sed -i "s/$current_ip/$desired_ip/g" "$netplan_file"
        fi

        # Apply the netplan configuration
        netplan apply
        log_message "IP address changed to $desired_ip in netplan file $netplan_file."
      done
    fi
  elif [ "$verbose" -eq 1 ]; then
    log_message "IP address is already set to $desired_ip. No changes needed."
  fi
}

# Function to change host entry in /etc/hosts
change_hostentry() {
  if [ -n "$desired_hostentry_name" ] && [ -n "$desired_hostentry_ip" ]; then
    # Ensure /etc/hosts contains the desired host entry
    grep -q "$desired_hostentry_ip" /etc/hosts
    if [ $? -ne 0 ]; then
      echo "$desired_hostentry_ip $desired_hostentry_name" >> /etc/hosts
      log_message "Host entry $desired_hostentry_name with IP $desired_hostentry_ip added to /etc/hosts."
    elif [ "$verbose" -eq 1 ]; then
      log_message "Host entry $desired_hostentry_name with IP $desired_hostentry_ip already exists in /etc/hosts. No changes needed."
    fi
  fi
}

# Apply the desired configurations
if [ -n "$desired_name" ]; then
  change_hostname
fi

if [ -n "$desired_ip" ]; then
  change_ip
fi

if [ -n "$desired_hostentry_name" ] && [ -n "$desired_hostentry_ip" ]; then
  change_hostentry
