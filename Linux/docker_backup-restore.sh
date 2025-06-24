#!/bin/bash

# Full Docker App Backup & Restore Tool
# Author: Utkarsh Raj

set -euo pipefail

TMP_DIR="/tmp/docker-app-action-$(date +%s)"
mkdir -p "$TMP_DIR"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

function print_header() {
  clear
  cat << "EOF"
       /\
      /**\
     /****\   DOCKER APP BACKUP & RESTORE TOOL
    /      \  -------------------------------
   /  /\    \       Author: Utkarsh Raj
  /  /  \    \
 /__/____\____\
EOF
  echo
}

function docker_compose_check() {
  if ! command -v docker-compose &>/dev/null; then
    echo "[!] docker-compose not found. Please install it if needed."
  fi
}

function list_containers() {
  docker ps -a --format '{{.Names}}'
}

function backup_container() {
  local container_name=$1
  local backup_path=$2

  echo "[*] Backing up container: $container_name"
  local image_name
  image_name=$(docker inspect "$container_name" --format '{{.Config.Image}}')
  local volumes=($(docker inspect "$container_name" --format '{{range .Mounts}}{{if .Name}}{{.Name}} {{end}}{{end}}'))

  mkdir -p "$TMP_DIR"

  for vol in "${volumes[@]}"; do
    echo "[*] Backing up volume: $vol"
    mkdir -p "$TMP_DIR/volumes/$vol"
    docker run --rm -v "$vol":/from -v "$TMP_DIR/volumes/$vol":/to alpine sh -c "cd /from && cp -a . /to/"
  done

  docker save "$image_name" -o "$TMP_DIR/image.tar"
  docker inspect "$container_name" > "$TMP_DIR/container-inspect.json"

  mkdir -p "$backup_path"
  cp -r "$TMP_DIR"/* "$backup_path/"
  echo "[*] Backup complete: $backup_path"
}

function restore_container() {
  local snapshot_path=$1
  local container_dir
  for container_dir in "$snapshot_path"/*/; do
    [ -d "$container_dir" ] || continue
    echo "[*] Restoring from $container_dir"
    cp -r "$container_dir"/* "$TMP_DIR/"

    [ -f "$TMP_DIR/image.tar" ] && docker load -i "$TMP_DIR/image.tar"
    if [ -d "$TMP_DIR/volumes" ]; then
      for vol_dir in "$TMP_DIR/volumes/"*; do
        vol_name=$(basename "$vol_dir")
        docker volume create "$vol_name" >/dev/null 2>&1 || true
        docker run --rm -v "$vol_name":/to -v "$vol_dir":/from alpine sh -c "cd /from && cp -a . /to/"
      done
    fi

    if [ -f "$TMP_DIR/project/docker-compose.yml" ]; then
      cp "$TMP_DIR/project/docker-compose.yml" .
      [ -f "$TMP_DIR/project/.env" ] && cp "$TMP_DIR/project/.env" .
      if command -v docker-compose >/dev/null 2>&1; then
        docker-compose up -d
      else
        echo "[!] docker-compose not found. Please run manually."
      fi
    fi
    rm -rf "$TMP_DIR/*"
  done
  echo "[*] Restore complete."
}

# FLAG-BASED MODE
if [[ "$#" -gt 0 ]]; then
  case "$1" in
    --backup-all)
      shift
      DEST_LOCAL=""
      DEST_REMOTE=""
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          --dest-local)
            DEST_LOCAL="$2"
            shift 2
            ;;
          --dest-remote)
            DEST_REMOTE="$2"
            shift 2
            ;;
        esac
      done

      for name in $(list_containers); do
        echo "[*] Backing up: $name"
        backup_path="$TMP_DIR/$name"
        backup_container "$name" "$backup_path"

        if [[ -n "$DEST_LOCAL" ]]; then
          final_path="$DEST_LOCAL/$name/$DATE"
          mkdir -p "$final_path"
          cp -r "$backup_path"/* "$final_path/"
          echo "[*] Saved to local: $final_path"
        fi

        if [[ -n "$DEST_REMOTE" ]]; then
          remote_path="$DEST_REMOTE/$name/$DATE"
          rclone copy "$backup_path" "$remote_path" --progress
          echo "[*] Uploaded to remote: $remote_path"
        fi
      done
      exit 0
      ;;

    --restore-all)
      shift
      SRC_LOCAL=""
      SRC_REMOTE=""
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          --source-local)
            SRC_LOCAL="$2"
            shift 2
            ;;
          --source-remote)
            SRC_REMOTE="$2"
            shift 2
            ;;
        esac
      done

      if [[ -n "$SRC_LOCAL" ]]; then
        restore_container "$SRC_LOCAL"
      elif [[ -n "$SRC_REMOTE" ]]; then
        echo "[*] Downloading remote snapshot folder to temp..."
        rclone copy -v "$SRC_REMOTE" "$TMP_DIR" --progress
        restore_container "$TMP_DIR"
      else
        echo "[!] No source path provided."
        exit 1
      fi
      exit 0
      ;;
    *)
      echo "[!] Unknown flag: $1"
      exit 1
      ;;
  esac
fi

# INTERACTIVE MODE
print_header
select mode in "Backup one" "Backup all" "Restore one" "Restore all" "Quit"; do
  case $mode in
    "Backup one")
      containers=($(list_containers))
      for i in "${!containers[@]}"; do echo "  [$i] ${containers[$i]}"; done
      read -p "Select container (0-${#containers[@]}): " index
      name="${containers[$index]}"
      read -e -p "Enter local backup directory: " path
      backup_container "$name" "$path/$name/$DATE"
      break
      ;;
    "Backup all")
      read -e -p "Enter local backup directory: " path
      for name in $(list_containers); do
        backup_container "$name" "$path/$name/$DATE"
      done
      break
      ;;
    "Restore one")
      read -e -p "Enter path to container snapshot folder: " path
      restore_container "$path"
      break
      ;;
    "Restore all")
      read -e -p "Enter path to root snapshot folder: " path
      restore_container "$path"
      break
      ;;
    "Quit")
      exit 0
      ;;
  esac
  break
Done
