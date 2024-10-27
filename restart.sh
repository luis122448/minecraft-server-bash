#!/bin/bash
set -e

# Environment variables
source /etc/environment

# Stop the application
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

# Update the modpack
echo "Copying server mods"
if [ -d "./data/server/nogui/mods" ]; then
  rm -rf ./data/server/nogui/mods
  cp -r ./mods /var/www/minecraft-server/volumes/server/nogui
else
  echo "No server mods found"
fi

# Build and run the application
sudo docker compose up --build --force-recreate --no-deps -d