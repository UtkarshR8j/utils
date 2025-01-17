#!/bin/bash

# Default values
SESSION_NAME=$(basename "$PWD")  # Use the current directory name as the default session name
PORT=3000
SKIP_BUILD=false

# Usage function
usage() {
  echo "Usage: $0 [-b] [-n <session_name>] [-p <port_number>]"
  echo "  -b                 Skip 'npm run build' step"
  echo "  -n <session_name>  Specify a custom tmux session name (default: directory name)"
  echo "  -p <port_number>   Specify the port number for the server (default: 3000)"
  exit 1
}

# Parse command-line options
while getopts ":n:p:b" opt; do
  case ${opt} in
    n) SESSION_NAME=$OPTARG ;;
    p) PORT=$OPTARG ;;
    b) SKIP_BUILD=true ;;
    *) usage ;;
  esac
done

# Run npm run build unless the -b flag is set
if [ "$SKIP_BUILD" = false ]; then
  echo "Running npm run build..."
  npm run build
else
  echo "Skipping npm run build as per user input."
fi

# Check if the tmux session exists
tmux has-session -t "$SESSION_NAME" 2>/dev/null

# If the session exists, kill it
if [ $? -eq 0 ]; then
  echo "Killing existing tmux session: $SESSION_NAME"
  tmux kill-session -t "$SESSION_NAME"
else
  echo "No existing tmux session named $SESSION_NAME found."
fi

# Create a new tmux session in detached mode and run npm start with the specified port
echo "Creating a new tmux session: $SESSION_NAME"
tmux new-session -d -s "$SESSION_NAME" "PORT=$PORT npm start"

# Confirm success
echo "Session $SESSION_NAME restarted with npm start on port $PORT"
