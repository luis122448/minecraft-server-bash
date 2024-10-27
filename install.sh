#!/bin/bash
ser -e

# Environment variables
source /etc/environment

# Verify if version is provided
if [ -z "$1" ]; then
    echo "Version not provided $0 <version>"
    exit 1
fi

ENV_FILE=".env"
ENV_FILE_BAK=".env.bak"

# Backup environment file and create a new one
cp -r "$ENV_FILE" "$ENV_FILE_BAK" &&
rm -rf "$ENV_FILE" &&
touch "$ENV_FILE" &&

# Environment variables for the server
cat <<EOF > "$ENV_FILE"
# Important: This file is used by docker-compose.yml
EULA=true
SERVER_NAME="La Mantita Server"
SERVER_PORT=25565
VERSION=${1}

# Port
MINECRAFT_SERVER_APP_PORT=${MINECRAFT_SERVER_APP_PORT}
MINECRAFT_SERVER_RCON_PORT=${MINECRAFT_SERVER_RCON_PORT}

# Modpack
TYPE=CURSEFORGE
CF_SERVER_MOD=/data/mods/server.zip
CF_BASE_DIR=/data

# Rcon
ENABLE_RCON=true
RCON_PASSWORD=${RCON_PASSWORD}

# Memory
MEMORY=4G
INIT_MEMORY=2G
MAX_MEMORY=4G

TZ=America/Lima

# Server properties
MODE=survival
DIFFICULTY=hard
ALLOW_CHEATS=true
MAX_PLAYERS=20
ONLINE_MODE=false
SERVER_HOST=${SERVER_HOST}
SERVER_USER=${SERVER_USER}
ICON=/data/icon.png
ALLOW_FLIGHT=true

# Advanced
USE_AIKAR_FLAGS=true
LOG_TIMESTAMP=true
EOF

# Backup server data
bash backup.sh &&

rm -rf /var/www/minecraft-server/volumes/data &&

echo "Zipping server config Forge"
zip -r ./server/server.zip ./server &&

echo "Copying server config Forge"
mkdir -p /var/www/minecraft-server/volumes/data/mods &&
cp -r ./server/server.zip /var/www/minecraft-server/volumes/data/mods/server.zip &&
rm -rf ./server/server.zip &&

echo "Copying server mods"
if [ -d "/var/www/minecraft-server/volumes/data/server/nogui/mods" ]; then
  rm -rf /var/www/minecraft-server/volumes/data/server/nogui/mods
  cp -r ./mods /var/www/minecraft-server/volumes/data/server/nogui
else
  mkdir -p /var/www/minecraft-server/volumes/data/server/nogui/mods
  cp -r ./mods /var/www/minecraft-server/volumes/data/server/nogui
fi