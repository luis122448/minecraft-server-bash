#!/bin/bash
set -e

# Environment variables
source /etc/environment

echo "Starting tunnel..."
ssh -i ./ssh/key.pem -N -R 25565:localhost:25565 ${SERVER_USER}@${SERVER_HOST}
