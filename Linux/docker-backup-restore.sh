#!/bin/bash

# Docker App Backup & Restore Tool
# Author: Utkarsh Raj

set -euo pipefail

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
TMP_DIR="/tmp/docker-app-action-$DATE"
mkdir -p "$TMP_DIR"

### HEADER DISPLAY ###
print_header() {
  clear
  cat << "EOF"

        /\
       /  \        DOCKER APP BACKUP & RESTORE TOOL
      /\  /\       -------------------------------
     /__\/__\           Author: Utkarsh Raj

EOF
}

check_docker_compose() {
  if ! command -v docker-compose &>/dev/null; then
    echo "[!] docker-compose not found. Please install it manually."
  fi
}

list_containers() {
  docker ps -a --format '{{.Names}}'
}

backup_container() {
  local container=$1
  local target=$2
  mkdir -p "$target"

  echo "[*] Backing up: $container"
  mkdir -p "$TMP_DIR"

  local image
  image=$(docker inspect "$container" --format '{{.Config.Image}}')
  docker inspect "$container" > "$TMP_DIR/container-inspect.json"
  docker save "$image" -o "$TMP_DIR/image.tar"

  mapfile -t named_volumes < <(docker inspect "$container" --format '{{range .Mounts}}{{if .Name}}{{.Name}}{{"\n"}}{{end}}{{end}}')
  for vol in "${named_volumes[@]}"; do
    echo "    - Volume: $vol"
    mkdir -p "$TMP_DIR/volumes/$vol"
    docker run --rm -v "$vol":/from -v "$TMP_DIR/volumes/$vol":/to alpine sh -c "[[ -d /from ]] && cd /from && cp -a . /to/ || echo '      [!] Volume $vol is empty or not mounted.'"
  done

  mapfile -t binds < <(docker inspect "$container" --format '{{range .Mounts}}{{if not .Name}}{{.Source}}::{{.Destination}}{{"\n"}}{{end}}{{end}}')
  for bind in "${binds[@]}"; do
    src=$(cut -d ':' -f1 <<< "$bind")
    dest=$(cut -d ':' -f2 <<< "$bind")
    key=$(echo "$dest" | tr '/:' '_')
    echo "    - Bind: $src -> $dest"
    if [[ -d "$src" ]]; then
      mkdir -p "$TMP_DIR/host_mounts/$key"
      cp -a "$src"/. "$TMP_DIR/host_mounts/$key/" || echo "      [!] Failed to copy bind mount"
    else
      echo "      [!] Skipped: $src does not exist"
    fi
  done

  cp -r "$TMP_DIR"/* "$target/"
  echo "[✓] Backup complete: $target"
}

restore_container() {
  local root=$1
  for dir in "$root"/*/; do
    echo "[*] Restoring snapshot: $dir"
    cp -r "$dir"/* "$TMP_DIR/"

    [ -f "$TMP_DIR/image.tar" ] && docker load -i "$TMP_DIR/image.tar"

    if [ -d "$TMP_DIR/volumes" ]; then
      for vol_dir in "$TMP_DIR/volumes/"*; do
        vol_name=$(basename "$vol_dir")
        echo "    - Restoring volume: $vol_name"
        docker volume create "$vol_name" >/dev/null 2>&1 || true
        docker run --rm -v "$vol_name":/to -v "$vol_dir":/from alpine sh -c "cd /from && cp -a . /to/"
      done
    fi

    if [ -d "$TMP_DIR/host_mounts" ]; then
      for mount_dir in "$TMP_DIR/host_mounts/"*; do
        key=$(basename "$mount_dir")
        dest=$(echo "$key" | sed 's/_/\//g')
        dest_path="/$dest"
        echo "    - Restoring bind: -> $dest_path"
        if [[ -d "$dest_path" && -w "$dest_path" ]]; then
          cp -a "$mount_dir"/. "$dest_path/" || echo "      [!] Failed to write to $dest_path"
        else
          echo "      [!] Skipped: $dest_path is not writable"
        fi
      done
    fi

    if [ -f "$TMP_DIR/project/docker-compose.yml" ]; then
      cp "$TMP_DIR/project/docker-compose.yml" .
      [ -f "$TMP_DIR/project/.env" ] && cp "$TMP_DIR/project/.env" .
      check_docker_compose && docker-compose up -d
    fi

    rm -rf "$TMP_DIR"/*
  done

  echo "[✓] Restore complete."
}

if [[ "$#" -gt 0 ]]; then
  case "$1" in
    --backup-all)
      shift
      DEST_LOCAL=""
      DEST_REMOTE=""
      while [[ "$#" -gt 0 ]]; do
        case "$1" in
          --dest-local) DEST_LOCAL="$2"; shift 2 ;;
          --dest-remote) DEST_REMOTE="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      for c in $(list_containers); do
        path="$TMP_DIR/$c"
        backup_container "$c" "$path"
        if [[ -n "$DEST_LOCAL" ]]; then
          final="$DEST_LOCAL/$c/$DATE"
          mkdir -p "$final"
          cp -r "$path"/* "$final/"
          echo "[✓] Local saved: $final"
        fi
        if [[ -n "$DEST_REMOTE" ]]; then
          rclone copy "$path" "$DEST_REMOTE/$c/$DATE" --progress
          echo "[✓] Remote uploaded: $DEST_REMOTE/$c/$DATE"
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
          --source-local) SRC_LOCAL="$2"; shift 2 ;;
          --source-remote) SRC_REMOTE="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      if [[ -n "$SRC_LOCAL" ]]; then
        restore_container "$SRC_LOCAL"
      elif [[ -n "$SRC_REMOTE" ]]; then
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

print_header
select option in "Backup one" "Backup all" "Restore one" "Restore all" "Quit"; do
  case $option in
    "Backup one")
      mapfile -t containers < <(list_containers)
      for i in "${!containers[@]}"; do echo "  [$i] ${containers[$i]}"; done
      read -p "Choose container (0-${#containers[@]}): " idx
      name="${containers[$idx]}"
      read -e -p "Backup directory: " path
      mkdir -p "$path"
      backup_container "$name" "$path/$name/$DATE"
      break
      ;;
    "Backup all")
      read -e -p "Backup directory: " path
      mkdir -p "$path"
      for name in $(list_containers); do
        backup_container "$name" "$path/$name/$DATE"
      done
      break
      ;;
    "Restore one")
      read -e -p "Snapshot path: " path
      restore_container "$path"
      break
      ;;
    "Restore all")
      read -e -p "Root of all snapshots: " path
      restore_container "$path"
      break
      ;;
    "Quit")
      echo "Bye!"
      exit 0
      ;;
  esac
done
