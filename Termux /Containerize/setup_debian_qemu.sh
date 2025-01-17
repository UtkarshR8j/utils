#!/bin/bash

# Enable verbose output for debugging and seeing each command executed
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

# Step 1: Install QEMU tools in Termux
print_message "=== Step 1: Installing QEMU Tools ===" "blue"
pkg update && pkg upgrade -y
pkg install qemu-utils qemu-common qemu-system-x86_64-headless tmux -y
print_message "QEMU tools installed successfully." "green"

# Step 2: Download Debian netinst ISO
print_message "=== Step 2: Downloading Debian netinst ISO ===" "blue"
mkdir -p ~/debian_qemu && cd ~/debian_qemu
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.1.0-amd64-netinst.iso -O debian-netinst.iso

# Step 3: Create a QEMU virtual disk for Debian
print_message "=== Step 3: Creating QEMU Virtual Disk ===" "blue"
qemu-img create -f qcow2 debian.img 8G
print_message "Virtual disk created (8GB)." "green"

# Step 4: Boot Debian installer using QEMU
print_message "=== Step 4: Booting Debian Installer ===" "blue"
tmux new-session -d -s debian_installer "qemu-system-x86_64 -machine q35 -m 2048 -smp cpus=2 -cpu qemu64 \
  -drive if=pflash,format=raw,read-only,file=$PREFIX/share/qemu/edk2-x86_64-code.fd \
  -drive file=debian.img,format=qcow2 \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 -device virtio-net,netdev=n1 \
  -cdrom debian-netinst.iso -nographic"
print_message "Debian installer is running in a tmux session named 'debian_installer'." "yellow"
print_message "Attach to the session using 'tmux attach-session -t debian_installer' to complete the installation." "yellow"

# Step 5: Boot Debian without the installer
print_message "=== Step 5: Booting Debian Without Installer ===" "blue"
tmux new-session -d -s debian_vm "qemu-system-x86_64 -machine q35 -m 2048 -smp cpus=2 -cpu qemu64 \
  -drive if=pflash,format=raw,read-only,file=$PREFIX/share/qemu/edk2-x86_64-code.fd \
  -drive file=debian.img,format=qcow2 \
  -netdev user,id=n1,hostfwd=tcp::9000-:22 -device virtio-net,netdev=n1 \
  -nographic"
print_message "Debian VM is running in a tmux session named 'debian_vm'." "yellow"

# Step 6: Configure SSH for Root Login
print_message "=== Step 6: Configuring SSH for Root Login ===" "blue"
print_message "Waiting for Debian to boot..." "yellow"
sleep 60 # Wait for Debian to boot up

print_message "Executing commands inside the Debian environment to configure SSH." "yellow"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[127.0.0.1]:9000" # Clear existing SSH fingerprints
sshpass -p "debian" ssh -o StrictHostKeyChecking=no root@127.0.0.1 -p 9000 << 'EOF'
apt update && apt install openssh-server -y
sed -i 's/^#Port 22/Port 9000/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo -e "utkarsh1850\nutkarsh1850" | passwd root
systemctl restart ssh
EOF

print_message "SSH configured successfully. You can now SSH into Debian using the command:" "green"
print_message "ssh root@<Termux_IP> -p 9000 (password: utkarsh1850)" "green"

print_message "Setup complete!" "green"


##requirements: termux>tmux>qemu>ssh