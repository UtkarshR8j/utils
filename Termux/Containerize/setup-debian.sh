#!/bin/bash

# Enable verbose output for debugging
set -x

# Function to print styled messages
print_message() {
    local message=$1
    local color=$2
    case $color in
        "green") echo -e "\033[1;32m$message\033[0m" ;;
        "yellow") echo -e "\033[1;33m$message\033[0m" ;;
        "blue") echo -e "\033[1;34m$message\033[0m" ;;
        "red") echo -e "\033[1;31m$message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Step 1: Clean up existing installations
print_message "=== Step 1: Cleaning up previous installations ===" "blue"
pkg update && pkg upgrade -y
pkg uninstall openssh proot proot-distro -y
rm -rf $PREFIX/etc/ssh /data/data/com.termux/files/usr/var/lib/proot-distro
print_message "Existing installations removed." "green"

# Step 2: Reinstall OpenSSH
print_message "=== Step 2: Installing OpenSSH in Termux ===" "blue"
pkg install openssh -y
sed -i 's/^#Port 22/Port 8022/' $PREFIX/etc/ssh/sshd_config
echo "PermitRootLogin yes" >> $PREFIX/etc/ssh/sshd_config
echo "PasswordAuthentication yes" >> $PREFIX/etc/ssh/sshd_config
echo -e "utkarsh1850\nutkarsh1850" | passwd
print_message "OpenSSH configured and password for Termux root set." "green"

# Step 3: Install proot-distro and set up Debian
print_message "=== Step 3: Installing and configuring Debian ===" "blue"
pkg install proot proot-distro -y
proot-distro install debian
print_message "Debian installed successfully." "green"

# Step 4: Set up root login and SSH in Debian
print_message "=== Step 4: Configuring Debian instance ===" "blue"
proot-distro login debian -- bash -c "
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
apt install openssh-server sudo -y
mkdir -p /run/sshd
chmod 0755 /run/sshd
sed -i 's/^#Port 22/Port 9000/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
echo 'root:utkarsh1850' | chpasswd
"
print_message "Root login enabled and SSH configured inside Debian." "green"

# Step 5: Start SSH in Debian
print_message "=== Step 5: Starting SSH inside Debian ===" "blue"
proot-distro login debian -- bash -c "/usr/sbin/sshd"
print_message "SSH started inside Debian on port 9000." "green"

# Step 6: Display SSH access information
print_message "=== Setup Complete ===" "blue"
TERMUX_IP=$(ip a | grep inet | grep -v inet6 | awk '{print $2}' | cut -d/ -f1)
DEBIAN_IP=$(proot-distro login debian -- bash -c "ip a | grep inet | grep -v inet6 | awk '{print $2}' | cut -d/ -f1")

print_message "To SSH into Termux: ssh root@$TERMUX_IP -p 8022" "yellow"
print_message "To SSH into Debian: ssh root@$DEBIAN_IP -p 9000" "yellow"
