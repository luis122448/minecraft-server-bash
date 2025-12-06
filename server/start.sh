#!/bin/bash

MEMORY="12G"

FORGE_JAR="forge-installer.jar"

java -Xmx$MEMORY -Xms$MEMORY -jar $FORGE_JAR --installServer nogui 