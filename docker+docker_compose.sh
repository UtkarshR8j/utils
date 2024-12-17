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
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common || { print_message "Failed to install prerequisites." "red"; exit 1; }

# Step 3: Add Docker's official GPG key
print_message "=== Adding Docker's GPG key ===" "blue"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || { print_message "Failed to add Docker's GPG key." "red"; exit 1; }

# Step 4: Add Docker repository
print_message "=== Adding Docker repository ===" "blue"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) test" || { print_message "Failed to add Docker repository." "red"; exit 1; }
sudo apt-get update || { print_message "Failed to update package lists after adding Docker repository." "red"; exit 1; }

# Step 5: Install Docker packages
print_message "=== Installing Docker packages ===" "blue"
sudo apt-get install -y docker-ce || { print_message "Failed to install Docker packages." "red"; exit 1; }

# Step 6: Check Docker service status
print_message "=== Checking Docker service status ===" "blue"
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker || { print_message "Docker service is not running." "red"; exit 1; }

# Step 7: Verify Docker installation
print_message "=== Verifying Docker installation ===" "blue"
docker --version || { print_message "Docker is not installed correctly." "red"; exit 1; }

print_message "Docker setup completed successfully!" "green"
