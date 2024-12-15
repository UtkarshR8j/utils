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

# Step 1: Update and install necessary packages
print_message "=== Installing prerequisites ===" "blue"
sudo apt update || { print_message "Failed to update package lists." "red"; exit 1; }
sudo apt install -y nginx openssl || { print_message "Failed to install NGINX or OpenSSL." "red"; exit 1; }

# Step 2: Ask user for configuration type
print_message "Do you want to configure NGINX for public IP or a domain?" "yellow"
echo "1. Public IP"
echo "2. Domain"
read -p "Enter your choice (1 or 2): " choice

# Step 3: Ask for port number
read -p "Enter the port number to proxy to (default: 5000): " port
port=${port:-5000}

if [[ "$choice" == "1" ]]; then
    # Public IP configuration
    print_message "=== Configuring NGINX for public IP ===" "blue"
    sudo mkdir -p /etc/nginx/custom
    cat <<EOF | sudo tee /etc/nginx/custom/reverse-proxy.conf
server {
    listen 80;

    server_name _;  # Accept connections from any host (public IP)

    location / {
        proxy_pass http://127.0.0.1:$port;  # Replace with your application's IP and port
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

elif [[ "$choice" == "2" ]]; then
    # Domain configuration
    read -p "Enter your domain name (e.g., example.com): " domain
    print_message "=== Configuring NGINX for domain: $domain ===" "blue"

    # Generate self-signed SSL certificate
    print_message "=== Generating SSL certificates ===" "blue"
    sudo mkdir -p /etc/nginx/ssl
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/$domain.key \
        -out /etc/nginx/ssl/$domain.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain" || { print_message "Failed to generate SSL certificates." "red"; exit 1; }

    # Create NGINX configuration
    sudo mkdir -p /etc/nginx/custom
    cat <<EOF | sudo tee /etc/nginx/custom/$domain.conf
server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $domain;

    ssl_certificate /etc/nginx/ssl/$domain.crt;
    ssl_certificate_key /etc/nginx/ssl/$domain.key;

    location / {
        proxy_pass http://127.0.0.1:$port;  # Replace with your application's IP and port
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

else
    print_message "Invalid choice. Exiting." "red"
    exit 1
fi

# Step 4: Test and restart NGINX
print_message "=== Testing NGINX configuration ===" "blue"
sudo nginx -t || { print_message "NGINX configuration test failed." "red"; exit 1; }

print_message "=== Restarting NGINX ===" "blue"
sudo systemctl restart nginx || { print_message "Failed to restart NGINX." "red"; exit 1; }

# Step 5: Verify setup
if [[ "$choice" == "1" ]]; then
    print_message "NGINX reverse proxy is set up for public IP on port $port. Visit http://<your-public-ip> to verify." "green"
elif [[ "$choice" == "2" ]]; then
    print_message "NGINX reverse proxy is set up for domain: $domain on port $port. Visit https://$domain to verify." "green"
fi
