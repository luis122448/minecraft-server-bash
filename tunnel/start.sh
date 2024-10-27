#!/bin/bash
set -e

# Environment variables
source /etc/environment

# Key permissions
chmod 600 /var/www/minecraft-server/configuration/minecraft-server-bash/ssh/key.pem

# Tunnel service
AUTOSSH="./tunnel/minecraft-tunnel.service"
rm -f "$AUTOSSH" &&

cat <<EOF > "$AUTOSSH"
[Unit]
Description=Túnel SSH persistente con autossh para el servidor de Minecraft
After=network.target

[Service]
User=${SERVER_LOCAL_USER}
ExecStart=/usr/bin/ssh -i /var/www/minecraft-server/configuration/minecraft-server-bash/ssh/key.pem -N -R ${MINECRAFT_SERVER_APP_PORT}:localhost:${MINECRAFT_SERVER_APP_PORT} -R ${MINECRAFT_SERVER_RCON_PORT}:localhost:${MINECRAFT_SERVER_RCON_PORT} ${SERVER_USER}@${SERVER_HOST}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "Copying minecraft-tunnel service"
sudo cp ./tunnel/minecraft-tunnel.service /etc/systemd/system/minecraft-tunnel.service

echo "Starting minecraft-tunnel service"
sudo systemctl daemon-reload
sudo systemctl enable minecraft-tunnel.service
sudo systemctl start minecraft-tunnel.service

# echo "minecraft-tunnel service status"
# sudo systemctl status minecraft-tunnel.service