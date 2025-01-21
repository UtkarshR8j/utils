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

# Step 1: Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    print_message "tmux not found, installing it..." "yellow"
    pkg install tmux -y
    print_message "tmux installed successfully." "green"
else
    print_message "tmux is already installed." "green"
fi

# Step 2: Check and handle running SSH processes
print_message "=== Step 2: Checking running SSH processes ===" "blue"

check_and_restart() {
    local instance=$1
    local session_name=$2
    local command=$3

    # Check if SSH process is running
    if pgrep -f "$command" > /dev/null; then
        print_message "SSH process is running in $instance." "yellow"
        read -p "Do you want to kill and restart the SSH process in $instance? (y/n): " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            print_message "Killing the existing SSH process in $instance..." "red"
            pkill -f "$command"
            tmux kill-session -t "$session_name" 2>/dev/null
            start_ssh "$instance" "$session_name" "$command"
        else
            print_message "Skipping restart for SSH in $instance." "yellow"
        fi
    else
        print_message "No SSH process found in $instance. Starting it now..." "green"
        start_ssh "$instance" "$session_name" "$command"
    fi
}

start_ssh() {
    local instance=$1
    local session_name=$2
    local command=$3

    # Start tmux session with the given command
    tmux has-session -t "$session_name" 2>/dev/null
    if [ $? != 0 ]; then
        tmux new-session -d -s "$session_name" "$command"
        print_message "Started SSH server in $instance using tmux." "green"
    else
        print_message "SSH server in $instance is already running in tmux." "green"
    fi
}

# Handle SSH for Termux
check_and_restart "Termux" "termux-ssh" "sshd -D"

# Handle SSH for Debian
check_and_restart "Debian" "debian-ssh" "proot-distro login debian -- /usr/sbin/sshd -D"

# Step 3: Provide user instructions
print_message "=== All servers are now running in the background ===" "blue"
print_message "To view logs or interact with any of the sessions, run the following commands:" "yellow"
print_message "  tmux attach-session -t termux-ssh  # For Termux SSH" "yellow"
print_message "  tmux attach-session -t debian-ssh  # For Debian SSH" "yellow"

#end