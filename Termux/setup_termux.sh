#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Update Termux package repository and upgrade installed packages
echo "Updating package repository..."
pkg update -y && pkg upgrade -y

# Define the list of packages to install
packages=("openssh" "git" "wget" "curl" "rclone" "tmux" "proot-distro")

# Install each package in the array
echo "Installing packages..."
for pkg in "${packages[@]}"; do
    echo "Installing $pkg..."
    pkg install -y "$pkg"
done

# Set a custom username
username="utkarsh"
echo "Setting username to $username..."

# Ensure Termux configuration directory exists
termux_config="$HOME/.termux"
mkdir -p "$termux_config"

# Customize the shell prompt with the new username
echo "Customizing shell prompt..."
if ! grep -q "export PS1=" "$HOME/.bashrc"; then
    echo "export PS1='[\u@$username:\w]\$ '" >> "$HOME/.bashrc"
fi

# Reload bash configuration
source "$HOME/.bashrc"

# Start the SSH server
echo "Starting SSH server..."
sshd

# Display the device's IP address for SSH access
echo "Fetching IP address..."
ip_address=$(ip addr show wlan0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
if [ -z "$ip_address" ]; then
    echo "Could not fetch the IP address. Ensure your device is connected to a network."
else
    echo "SSH server is running. Connect using the following command:"
    echo "ssh $username@$ip_address"
fi

# Success message
echo "Termux setup is complete!"
