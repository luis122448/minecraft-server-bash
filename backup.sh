#!/bin/bash
set -e

# Environment variables
source /etc/environment

# Stop containers
sudo docker compose down

# Backup process
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_DIR="/var/www/minecraft-server/backups"

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/volumes-$timestamp.zip"

echo "Creating backup of /volumes at $BACKUP_FILE"
zip -r "$BACKUP_FILE" /var/www/minecraft-server/volumes

echo "Removing backups older than 30 days"
find "$BACKUP_DIR" -name "*.zip" -type f -mtime +30 -exec rm {} \;

echo "Backup completed successfully"

# Start containers
sudo docker compose up --build --force-recreate --no-deps -d