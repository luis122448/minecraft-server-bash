#!/bin/bash

sleep 60

/usr/local/bin/rcon-cli -H localhost -P 25575 -p "$RCON_PASSWORD" gamerule naturalRegeneration false
/usr/local/bin/rcon-cli -H localhost -P 25575 -p "$RCON_PASSWORD" gamerule sleepPercentagePlayer 30
