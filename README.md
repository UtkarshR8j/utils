# Docker Backup and Sync Scripts

This repository includes two scripts:

- `docker_backup-restore.sh`: Backup and restore Docker containers (volumes and config).
- `sync.sh`: Sync backups to/from a remote server using `rsync`.

## Requirements

- `bash`
- `docker` and `docker-compose`
- `tar`, `rsync`, `ssh`
- SSH key-based access (for remote operations)

## Usage

### docker_backup-restore.sh

Run interactively:

```bash
bash docker_backup-restore.sh
```

This lets you choose between backing up or restoring one or more containers, locally or remotely.

#### Flag-based automation:

```bash
# Backup all containers locally
bash docker_backup-restore.sh --mode backup --all

# Backup specific container
bash docker_backup-restore.sh --mode backup --container audiobookshelf

# Restore specific container
bash docker_backup-restore.sh --mode restore --container audiobookshelf

# Backup all containers to a remote location
bash docker_backup-restore.sh --mode backup --all --remote user@host:/path

# Restore from a remote backup
bash docker_backup-restore.sh --mode restore --container audiobookshelf --remote user@host:/path

# Restore to a specific local path
bash docker_backup-restore.sh --mode restore --container audiobookshelf --extract-dir /path/to/extract
```

### sync.sh

Push or pull backups using `rsync`.

```bash
# Push local backups to remote
bash sync.sh push user@host:/path/to/backups

# Pull backups from remote to local
bash sync.sh pull user@host:/path/to/backups
```

## Directory Structure

```
.
├── docker_backup-restore.sh
├── sync.sh
├── backups/
│   └── <container>.tar.gz
└── docker-compose.yml  # required for restore
```
