#!/bin/bash
set -e

# --- Configuration Variables ---
SCRIPT_NAME=$(basename "$0")
MC_VERSION="" # Minecraft version
MC_MODE=""    # Game mode (survival, creative, adventure, spectator)
MC_TYPE=""    # Server type (vanilla, forge)
ENV_FILE=".env"
ENV_FILE_BAK=".env.bak"
RAM_SERVER="4G" # Default RAM allocation
SERVER_DIR="/var/www/minecraft-server" # Base server directory
RCON_PASSWORD="" # RCON password (should be set in environment)

# --- Functions ---

# Displays script usage
show_usage() {
    echo "Usage: $SCRIPT_NAME [OPTIONS]"
    echo ""
    echo "Initializes or updates the Minecraft server configuration."
    echo ""
    echo "Options:"
    echo "  -v <version>  Specify the Minecraft version (e.g., 1.20.1)"
    echo "  -m <mode>     Specify the game mode (survival, creative, adventure, spectator)"
    echo "  -t <type>     Specify the server type (vanilla, forge)"
    echo "  -r <ram>      Specify the RAM allocation for the server (default: ${RAM_SERVER})"
    echo "  -p <password> Specify the RCON password"
    echo "  -h            Show this help message"
    echo ""
    echo "If options are not provided, the script will prompt for them."
}

# Prompts for input with validation
prompt_input() {
    local prompt_text="$1"
    local var_name="$2"
    local allowed_values="$3" # Space-separated string of allowed values
    local default_value="$4"

    local input_value=""
    while true; do
        if [ -n "$default_value" ]; then
            read -p "$prompt_text [$default_value]: " input_value
        else
            read -p "$prompt_text: " input_value
        fi

        # Use default if input is empty and default exists
        if [ -z "$input_value" ] && [ -n "$default_value" ]; then
            input_value="$default_value"
            echo "Using default: $input_value"
        fi

        # Basic validation
        if [ -z "$input_value" ]; then
            echo "Error: This value is required."
        elif [ -n "$allowed_values" ]; then
            # Convert input to lowercase for case-insensitive comparison
            local lower_input=$(echo "$input_value" | tr '[:upper:]' '[:lower:]')
            local found=false
            for val in $allowed_values; do
                local lower_val=$(echo "$val" | tr '[:upper:]' '[:lower__]')
                if [ "$lower_input" == "$lower_val" ]; then
                    input_value="$lower_input" # Store the validated lowercase value
                    found=true
                    break
                fi
            done
            if [ "$found" = true ]; then
                break # Valid input
            else
                echo "Error: Invalid value '$input_value'. Allowed values are: $allowed_values"
            fi
        else
            # No specific allowed values, any non-empty is okay
            break
        fi
    done
    # Assign the validated value back to the variable passed by name
    eval "$var_name='$input_value'"
}

# --- Main Script Logic ---

# Environment variables
# Consider if sourcing /etc/environment is truly needed or if specific vars should be checked/prompted
source /etc/environment || echo "Warning: Could not source /etc/environment"

# --- Argument Parsing ---
while getopts ":v:m:t:h:r" opt; do
    case $opt in
        v)
            MC_VERSION="$OPTARG"
            ;;
        m)
            MC_MODE="$OPTARG"
            ;;
        t)
            MC_TYPE="$OPTARG"
            ;;
        r)
            RAM_SERVER="$OPTARG"
            ;;
        p)
            RCON_PASSWORD="$OPTARG"
            ;;
        h)
            show_usage
            exit 0
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument." >&2
            show_usage
            exit 1
            ;;
        \?)
            echo "Error: Invalid option -$OPTARG" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Shift off the options and their arguments
shift $((OPTIND-1))

# --- Interactive Prompts (if arguments not provided) ---

echo "--- Minecraft Server Setup ---"

# Prompt for Version
if [ -z "$MC_VERSION" ]; then
    prompt_input "Enter Minecraft version (e.g., 1.20.1)" MC_VERSION "" ""
    if [ -z "$MC_VERSION" ]; then
         echo "Error: Minecraft version is required."
         exit 1
    fi
fi

# Prompt for Mode
if [ -z "$MC_MODE" ]; then
    prompt_input "Enter game mode (survival, creative, adventure, spectator)" MC_MODE "survival creative adventure spectator" "survival"
fi

# Prompt for Type
if [ -z "$MC_TYPE" ]; then
    prompt_input "Enter server type (vanilla or forge)" MC_TYPE "vanilla forge" "vanilla"
fi

echo ""
echo "--- Configuration Summary ---"
echo "Version: $MC_VERSION"
echo "Mode:    $MC_MODE"
echo "Type:    $MC_TYPE"
echo "RAM:     $RAM_SERVER"
echo "---------------------------"
echo ""

# --- Pre-setup Checks and Directory Management ---

# Change owner of the directory
# Note: Running this with sudo might require password. Ensure script is run as root or with appropriate sudoers config.
echo "Setting ownership for $SERVER_DIR..."
sudo chown -R "$USER":"$USER" "$SERVER_DIR" || { echo "Error: Failed to set ownership. Check permissions or run with sudo."; exit 1; }
echo "Ownership set."

# Create directories if not exists
echo "Ensuring necessary directories exist..."
if [ ! -d "$SERVER_DIR/volumes" ]; then
    echo "Creating $SERVER_DIR/volumes..."
    sudo mkdir -p "$SERVER_DIR/volumes" || { echo "Error: Failed to create volumes directory."; exit 1; }
fi

if [ ! -d "$SERVER_DIR/backups" ]; then
    echo "Creating $SERVER_DIR/backups..."
    sudo mkdir -p "$SERVER_DIR/backups" || { echo "Error: Failed to create backups directory."; exit 1; }
fi
echo "Directories checked."

# --- .env File Generation ---

echo "Generating .env file..."

# Backup environment file and create a new one
# Using printf to build the content string allows for easier conditional sections
ENV_CONTENT="# Important: This file is used by docker-compose.yml\n"
ENV_CONTENT+="EULA=true\n" # Assuming EULA is always accepted
ENV_CONTENT+="SERVER_NAME=\"La Mantita Server\"\n"
ENV_CONTENT+="SERVER_PORT=25565\n" # Default server port
ENV_CONTENT+="VERSION=${MC_VERSION}\n"
ENV_CONTENT+="\n"
ENV_CONTENT+="# Port Configuration\n"
ENV_CONTENT+="MINECRAFT_SERVER_APP_PORT=25565\n"
ENV_CONTENT+="MINECRAFT_SERVER_RCON_PORT=25575\n"
ENV_CONTENT+="\n"

# Add type-specific configuration
if [ "$MC_TYPE" == "forge" ]; then
    ENV_CONTENT+="# Server Type: Forge (or Modded based on image)\n"
    ENV_CONTENT+="TYPE=FORGE\n" # Changed from CURSEFORGE, depends on image
    # These paths are highly image-dependent. Keep them if they match your Docker image.
    ENV_CONTENT+="CF_SERVER_MOD=/data/mods/server.zip\n"
    ENV_CONTENT+="CF_BASE_DIR=/data\n"
    ENV_CONTENT+="\n"
elif [ "$MC_TYPE" == "vanilla" ]; then
    ENV_CONTENT+="# Server Type: Vanilla\n"
    ENV_CONTENT+="TYPE=VANILLA\n"
    ENV_CONTENT+="\n"
fi

ENV_CONTENT+="# RCON Configuration\n"
ENV_CONTENT+="ENABLE_RCON=true\n"
ENV_CONTENT+="RCON_PASSWORD=${RCON_PASSWORD}\n"
ENV_CONTENT+="\n"
ENV_CONTENT+="# Memory Allocation\n"
ENV_CONTENT+="MEMORY=${RAM_SERVER}\n"      # Total memory for container
ENV_CONTENT+="INIT_MEMORY=${RAM_SERVER}\n" # Initial Java heap size
ENV_CONTENT+="MAX_MEMORY=${RAM_SERVER}\n"  # Maximum Java heap size
ENV_CONTENT+="\n"
ENV_CONTENT+="TZ=America/Lima\n" # Timezone
ENV_CONTENT+="\n"
ENV_CONTENT+="# Server Properties (server.properties)\n"
ENV_CONTENT+="MODE=${MC_MODE}\n" # Use the chosen mode
ENV_CONTENT+="DIFFICULTY=hard\n"
ENV_CONTENT+="ALLOW_CHEATS=true\n" # Assuming cheats allowed for setup/admin
ENV_CONTENT+="MAX_PLAYERS=20\n"
ENV_CONTENT+="ONLINE_MODE=false\n" # Be cautious with false unless intended for offline mode/LAN
ENV_CONTENT+="ICON=/data/icon.png\n" # Path inside the container volume
ENV_CONTENT+="ALLOW_FLIGHT=true\n"
ENV_CONTENT+="\n"
ENV_CONTENT+="# Advanced Settings\n"
ENV_CONTENT+="USE_AIKAR_FLAGS=true\n" # Recommended for performance on recent Java
ENV_CONTENT+="LOG_TIMESTAMP=true\n"

# Create backup and write the new .env file
cp -f "$ENV_FILE" "$ENV_FILE_BAK" 2>/dev/null || echo "No existing $ENV_FILE to backup."
printf "%b" "$ENV_CONTENT" > "$ENV_FILE" || { echo "Error: Failed to write $ENV_FILE."; exit 1; }
echo ".env file generated."

# --- Update server/start.sh ---
echo "Updating memory allocation in server/start.sh..."
if [ -f "./server/start.sh" ]; then
    # Use sed to replace the MEMORY variable, handling potential quotes
    sed -i "s/^MEMORY=.*$/MEMORY=\"${RAM_SERVER}\"/" "./server/start.sh" || { echo "Error: Failed to update server/start.sh."; exit 1; }
    echo "server/start.sh updated with MEMORY=${RAM_SERVER}."
else
    echo "Warning: ./server/start.sh not found. Skipping update."
fi

# --- Server Data Management ---

# Backup server data (assuming backup.sh exists and works)
echo "Running backup script..."
if [ -f "./backup.sh" ]; then
    bash ./backup.sh || echo "Warning: backup.sh failed."
else
    echo "Warning: backup.sh not found in the current directory. Skipping backup."
fi
echo "Backup process finished (or skipped)."

# Remove current server data (this will cause the server to regenerate a new world!)
# Only do this if you intend to start with a fresh world or if the Docker image handles persistence differently.
# CAUTION: This removes your world!
echo "Removing current server data ($SERVER_DIR/volumes/data)..."
# Add a confirmation prompt if this is destructive behavior!
# read -p "WARNING: This will delete your current world data. Continue? (y/N): " confirm_delete
# if [[ "$confirm_delete" =~ ^[Yy]$ ]]; then
    rm -rf "$SERVER_DIR/volumes/data" || { echo "Error: Failed to remove server data."; exit 1; }
    echo "Server data removed."
# else
#    echo "Data removal skipped by user."
#    # Decide if you should exit or continue without clearing data
#    # If continuing, the next steps (initialize/copy) might be incorrect
# fi


# Initialize server data - This part seems specific to a particular Docker image/setup
# It zips a local 'server' directory and copies it to the volumes. This is unusual.
# Ensure this matches how your Docker image expects initial data or a modpack.
echo "Initialize server data (based on local ./server directory)..."
if [ -d "./server" ]; then
    echo "Zipping ./server directory..."
    zip -r ./server/server.zip ./server || { echo "Error: Failed to zip ./server directory."; exit 1; }

    echo "Creating data/mods directory in volumes..."
    mkdir -p "$SERVER_DIR/volumes/data/mods" || { echo "Error: Failed to create data/mods directory in volumes."; exit 1; }

    echo "Copying server.zip to volumes/data/mods..."
    cp -r ./server/server.zip "$SERVER_DIR/volumes/data/mods/server.zip" || { echo "Error: Failed to copy server.zip."; exit 1; }

    echo "Removing temporary server.zip..."
    rm -rf ./server/server.zip || echo "Warning: Failed to remove temporary server.zip."
    echo "Server data initialization complete."
else
    echo "Warning: Local ./server directory not found. Skipping server data initialization."
fi


# Copy server mods - This is only relevant for Forge/Modded servers
if [ "$MC_TYPE" == "forge" ]; then
    echo "Copying server mods (for Forge)..."
    if [ -d "./mods" ]; then
        # This path '/var/www/minecraft-server/volumes/data/server/nogui/mods' is specific.
        # Ensure this matches where your Forge Docker image expects mods.
        MODS_TARGET_DIR="$SERVER_DIR/volumes/data/server/nogui/mods"
        echo "Target mods directory: $MODS_TARGET_DIR"

        # Clear existing mods if directory exists
        if [ -d "$MODS_TARGET_DIR" ]; then
          echo "Clearing existing mods in $MODS_TARGET_DIR..."
          rm -rf "$MODS_TARGET_DIR" || echo "Warning: Failed to remove existing mods."
        fi

        echo "Creating $MODS_TARGET_DIR..."
        mkdir -p "$MODS_TARGET_DIR" || { echo "Error: Failed to create mods target directory."; exit 1; }

        echo "Copying ./mods to $MODS_TARGET_DIR..."
        cp -r ./mods/* "$MODS_TARGET_DIR/" || echo "Warning: Failed to copy mods. Ensure ./mods contains mod files/directories."
        echo "Mod copying complete."
    else
        echo "Warning: Local ./mods directory not found. Skipping mod copying."
    fi
else
    echo "Server type is Vanilla. Skipping mod copying."
fi

# Copy server icon
echo "Copying server icon..."
if [ -f "./resources/icon.png" ]; then
    ICON_TARGET_DIR="$SERVER_DIR/volumes/data"
    echo "Target icon directory: $ICON_TARGET_DIR"
    mkdir -p "$ICON_TARGET_DIR" # Ensure target directory exists
    cp -r ./resources/icon.png "$ICON_TARGET_DIR/icon.png" || echo "Warning: Failed to copy server icon."
    echo "Server icon copied."
else
    echo "Warning: Local ./resources/icon.png not found. Skipping icon copying."
fi

echo ""
echo "Minecraft server initial configuration complete."
echo "You should now be able to start your Docker container using docker-compose."