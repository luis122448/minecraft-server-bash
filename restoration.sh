#!/bin/bash
set -e

# Environment variables
source /etc/environment

# Verify if the backup file is provided
if [ -z "$1" ]; then
    echo "File not provided $0 <rute-of-backup>"
    exit 1
fi

BACKUP_FILE="/var/www/minecraft-server/backups/$1"
BACKUP_DIR="/var/www/minecraft-server/backups"
VOLUME_DIR="/var/www/minecraft-server/volumes"

# Verify if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "El archivo de backup $BACKUP_FILE no existe."
    exit 1
fi

# Stop containers
sudo docker compose down

# Clean volumes
sudo rm -rf "$VOLUME_DIR"
mkdir -p "$VOLUME_DIR"

echo "Restoring backup from $BACKUP_FILE..."
sudo unzip "$BACKUP_FILE" -d "$VOLUME_DIR"

# Start containers
sudo docker compose up --build --force-recreate --no-deps -d