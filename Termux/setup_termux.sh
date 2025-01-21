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

# Allow user 'utkarsh' to ssh into Termux by modifying SSH config
echo "Configuring SSH for utkarsh..."

# Ensure the SSH config file allows the user 'utkarsh' to connect
sshd_config="/data/data/com.termux/files/usr/etc/ssh/sshd_config"

# Check if the AllowUsers line exists and add 'utkarsh' if not present
if ! grep -q "AllowUsers" "$sshd_config"; then
    echo "AllowUsers utkarsh" >> "$sshd_config"
else
    # If AllowUsers already exists, add 'utkarsh' to it
    sed -i 's/AllowUsers.*/& utkarsh/' "$sshd_config"
fi

# Restart the SSH service to apply changes
echo "Restarting SSH service..."
sshd

# Success message
echo "Termux setup is complete!"




