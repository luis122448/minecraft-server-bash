#!/bin/bash
set -e

sudo systemctl stop minecraft-tunnel.service
sudo systemctl disable minecraft-tunnel.service