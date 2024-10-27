#!/bin/bash
set -e

sudo systemctl stop autossh-tunnel.service
sudo systemctl disable autossh-tunnel.service