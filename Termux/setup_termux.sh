#!/bin/bash

# Update Termux package repository and upgrade installed packages
echo "Updating package repository..."
pkg update -y && pkg upgrade -y

# Define the list of packages to install
setup=(openssh git wget curl rclone tmux proot-distro)

# Install each package in the setup array
echo "Installing packages..."
for pkg in "${setup[@]}"; do
    pkg install -y "$pkg"
done

# Change username to "utkarsh" in Termux (create .termux file for configuration)
username="utkarsh"
echo "Changing username to $username..."
termux_config="$HOME/.termux"
if [ ! -d "$termux_config" ]; then
    mkdir "$termux_config"
fi

# Customize shell prompt with new username
echo "export PS1='[\u@$username:\w]\$ '" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

# Start SSH server
echo "Starting SSH server..."
sshd

# Display the IP address for SSH access
ip_address=$(ifconfig | grep -oP '(?<=inet )\d+\.\d+\.\d+\.\d+' | head -1)
echo "SSH server is running. Connect using the following IP address:"
echo "ssh $username@$ip_address"

# Success message
echo "Termux setup is complete!"