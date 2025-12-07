#!/bin/bash
set -e

# --- Configuration ---
# This path should match the base directory used in your docker-compose and install scripts.
SERVER_DIR="/var/www/minecraft-server"
DATA_DIR="$SERVER_DIR/volumes/data"

# --- Main Script ---

echo "--- Minecraft Server Data Cleaner ---"
echo ""
echo "This script will permanently delete the following:"
echo "1. All world data, player data, and server logs."
echo "2. Any files inside the main data volume."
echo ""
echo "This is intended for a clean start with a new world or mods."
echo "The Minecraft Docker container will be stopped before cleaning."
echo ""
echo "Target directory to be deleted: $DATA_DIR"
echo ""

# Confirmation prompt
read -p "WARNING: This action is irreversible. Are you sure you want to continue? (y/N): " confirm_delete

if [[ ! "$confirm_delete" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled by user."
    exit 0
fi

echo ""
echo "Stopping Minecraft server..."
# Use docker-compose down to stop and remove the container
docker compose down || { echo "Warning: Failed to stop the container. It might not be running."; }
echo "Server stopped."

echo "Cleaning server data..."

if [ -d "$DATA_DIR" ]; then
    echo "Deleting $DATA_DIR..."
    # Use sudo because the directories might be owned by root depending on docker's setup
    sudo rm -rf "$DATA_DIR"
    echo "Server data successfully deleted."
else
    echo "Warning: Data directory not found. Nothing to delete."
fi

# Re-create the data directory so volumes can be mounted on next start
echo "Re-creating empty data directory..."
sudo mkdir -p "$DATA_DIR"
# The install script sets ownership to the user, let's do the same.
echo "Setting ownership for $DATA_DIR..."
sudo chown -R "$USER":"$USER" "$DATA_DIR" || { echo "Error: Failed to set ownership. Check permissions or run with sudo."; exit 1; }


echo ""
echo "Cleaning process complete."
echo "You can now run the install.sh script or manually place your new server files and start the server."
