#!/bin/bash

#Check and Update netplan configuration
update_netplan(){
echo "Checking netplan configuration.."
if grep -q "192.168.16.21/24" /etc/netplan/00-installer-config.yaml; then
	echo "Netplan configuration is configured correctly."
else
	echo "Please wait, updating netplan configuration.."
	sudo cp /ect/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.bak
	sudo bash -c 'cat << EOF > /etc/netplan/00-installer-config.yaml

network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.1
      nameservers: [8.8.8.8, 8.8.4.4]
EOF'
	sudo netplan apply
	echo "Netplan configuration updated."
fi
}

#Check and Update /ect/hosts
update_hosts() {
echo "Checking /etc/hosts file..."
if grep -q "192.168.16.21 server1" /etc/hosts; then
	echo "Host file is configured correctly."
else
	echo "Updating host file..."
	sudo bash -c 'echo "192.168.16.21 server1" >> /etc/hosts'
	echo "Hosts file updated."
fi
}

#Check and Install required software
install_software() {
echo "Checking for required software..."
packages=("apache2" "squid")
	for package in "${packages[@]}"; do
		if dpkg -l | grep -q "$package"; then
			echo "$package is already installed."
		else
			echo "Installing $package..."
			sudo apt update && sudo apt install -y "$package"
		fi
	done

echo "Ensuring services are running..."
sudo systemctl start apache2
sudo systemctl start squid
}

#Check and create user accounts
create_users() {
echo "Creating user accounts..."
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

	for user in "${users[@]}"; do
		if id "$user" &>/dev/null; then
			echo "User $user already exists."
		else
			echo "Creating user $user..."
			sudo useradd -m -s /bin/bash "$user"
			echo "$user has been created."

			#Setup SSH Keys for dennis
			if [[ "$user" == "dennis" ]]; then
				echo "Setting up SSH for $user..."
				sudo mkdir -p /home/"$user"/.ssh
				echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" \ sudo tee /home/"$user"/.ssh/authorized_keys
				sudo chown -R "$user":"$user" /home/"$user"/.ssh
				echo "SSH key set up for $user."
			fi
		fi
	done
}

#Script Execution
echo "Starting server configuration..."

update_netplan
update_hosts
install_software
create_users

echo "Server configuration complete!"



