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
BACKUP_FILE="$BACKUP_DIR/volumes-$TIMESTAMP.zip"

echo "Creating backup of /volumes at $BACKUP_FILE"
cd /var/www/minecraft-server/volumes/
zip -r "$BACKUP_FILE" .

echo "Removing backups older than 30 days"
find "$BACKUP_DIR" -name "*.zip" -type f -mtime +30 -exec rm {} \;

echo "Backup completed successfully"

# Start containers
cd /var/www/minecraft-server/configurations/minecraft-server-bash/
sudo docker compose up --build --force-recreate --no-deps -d