#!/bin/bash

echo "Copying server mods"
if [ -d "./data/server/nogui/mods" ]; then
  rm -rf ./data/server/nogui/mods
  cp -r ./mods ./data/server/nogui
else
  echo "No server mods found"
fi

echo "Restarting server"
bash deploy.sh