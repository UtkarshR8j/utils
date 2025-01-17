#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo"
  exit 1
fi

# Detect package manager
if command -v yum &> /dev/null; then
  PACKAGE_MANAGER="yum"
elif command -v apt &> /dev/null; then
  PACKAGE_MANAGER="apt"
else
  echo "Unsupported package manager. This script supports yum (Amazon Linux, RHEL) or apt (Debian, Ubuntu)."
  exit 1
fi

# Update the system
echo "Updating system..."
if [ "$PACKAGE_MANAGER" == "yum" ]; then
  sudo yum update -y
elif [ "$PACKAGE_MANAGER" == "apt" ]; then
  sudo apt update -y && sudo apt upgrade -y
fi

# Install Docker
echo "Installing Docker..."
if [ "$PACKAGE_MANAGER" == "yum" ]; then
  sudo yum install -y docker
elif [ "$PACKAGE_MANAGER" == "apt" ]; then
  sudo apt install -y docker.io
fi

# Start Docker service
echo "Starting Docker service..."
if command -v service &> /dev/null; then
  sudo service docker start
else
  sudo systemctl start docker
fi

# Add user to Docker group
echo "Adding $(whoami) to the Docker group..."
sudo usermod -aG docker "$(whoami)"

echo "Docker installation complete. Please logout and log back in to verify."

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker and Docker Compose installation
echo "Verifying installations..."
docker info || echo "Docker is not working yet. Ensure you have logged out and logged back in."
docker-compose version || echo "Docker Compose installation failed. Check the curl command or permissions."
