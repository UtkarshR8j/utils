#!/bin/bash

# Interactive Rclone Backup & Restore Tool
# Author: Utkarsh

clear
echo "=========================="
echo " 📦 RCLONE BACKUP TOOL"
echo "=========================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# 1. List rclone remotes
echo "[*] Available remotes on your system:"
remotes=($(rclone listremotes))
if [ ${#remotes[@]} -eq 0 ]; then
  echo "No remotes found. Please run 'rclone config' first."
  exit 1
fi

for i in "${!remotes[@]}"; do
  echo "  [$i] ${remotes[$i]}"
done

echo
read -p "Select the remote to use (0-${#remotes[@]}): " remote_index
selected_remote="${remotes[$remote_index]}"
echo "✅ Selected: $selected_remote"

# 2. Ask backup folder path on remote
read -p "Enter the remote backup path (e.g., backups/docmost): " remote_path
remote_full="$selected_remote$remote_path"

echo
echo "[*] Checking remote directory: $remote_full"
rclone ls "$remote_full" 2>/dev/null || echo "(empty or does not exist)"
echo

read -p "Do you want to (B)ackup or (R)estore? [B/R]: " action

# 3. Backup process
if [[ "$action" == "B" || "$action" == "b" ]]; then
  echo
  echo "[*] Backup mode selected"
  read -p "Are you sure you want to copy all contents of $SCRIPT_DIR to $remote_full/$DATE ? [y/N]: " confirm

  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo
    echo "[*] Starting backup..."
    rclone copy "$SCRIPT_DIR" "$remote_full/$DATE" --progress --copy-links --fast-list --links
    echo "✅ Backup complete to $remote_full/$DATE"
  else
    echo "❌ Backup cancelled."
    exit 0
  fi

# 4. Restore process
elif [[ "$action" == "R" || "$action" == "r" ]]; then
  echo
  echo "[*] Restore mode selected"

  echo "[*] Fetching available snapshots from $remote_full..."
  folders=($(rclone lsf "$remote_full" --dirs-only))
  if [ ${#folders[@]} -eq 0 ]; then
    echo "No backups found in $remote_full"
    exit 1
  fi

  for i in "${!folders[@]}"; do
    echo "  [$i] ${folders[$i]}"
  done

  read -p "Select a snapshot to restore: " snapshot_index
  selected_snapshot="${folders[$snapshot_index]}"
  remote_snapshot="$remote_full/$selected_snapshot"

  echo
  read -p "Restore $remote_snapshot into current folder $SCRIPT_DIR? [y/N]: " confirm_restore
  if [[ "$confirm_restore" == "y" || "$confirm_restore" == "Y" ]]; then
    echo "[*] Restoring..."
    rclone sync "$remote_snapshot" "$SCRIPT_DIR" --progress
    echo "✅ Restore complete."
  else
    echo "❌ Restore cancelled."
    exit 0
  fi
else
  echo "Invalid option. Exiting."
  exit 1
fi
