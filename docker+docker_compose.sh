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

# Exit the script on any error
set -e

# Step 1: Update package lists
print_message "=== Updating package lists ===" "blue"
sudo apt-get update || { print_message "Failed to update package lists." "red"; exit 1; }

# Step 2: Install prerequisites
print_message "=== Installing prerequisites ===" "blue"
sudo apt-get install -y ca-certificates curl || { print_message "Failed to install prerequisites." "red"; exit 1; }

# Step 3: Add Docker's official GPG key
print_message "=== Adding Docker's GPG key ===" "blue"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || { print_message "Failed to download Docker's GPG key." "red"; exit 1; }
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Step 4: Add Docker repository
print_message "=== Adding Docker repository ===" "blue"
echo \  
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \" 
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || { print_message "Failed to add Docker repository." "red"; exit 1; }
sudo apt-get update || { print_message "Failed to update package lists after adding Docker repository." "red"; exit 1; }

# Step 5: Install Docker packages
print_message "=== Installing Docker packages ===" "blue"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || { print_message "Failed to install Docker packages." "red"; exit 1; }

# Step 6: Install Docker Compose
print_message "=== Installing Docker Compose ===" "blue"
sudo apt install -y docker-compose || { print_message "Failed to install Docker Compose." "red"; exit 1; }

# Step 7: Check Docker status
print_message "=== Checking Docker service status ===" "blue"
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker || { print_message "Docker service is not running." "red"; exit 1; }

# Step 8: Verify Docker and Docker Compose installation
print_message "=== Verifying Docker installation ===" "blue"
docker --version || { print_message "Docker is not installed correctly." "red"; exit 1; }
docker-compose --version || { print_message "Docker Compose is not installed correctly." "red"; exit 1; }

print_message "Docker and Docker Compose setup completed successfully!" "green"
