![Logo del Projecto](./resources/logo.png)

# Minecraft Forge Docker Server

This project is a Minecraft Forge Server that runs in a Docker container. The server is deployed on a remote server using an SSH tunnel. The project includes a deployment script that automates the deployment process.

---
## Requirements

- docker
- git
- tree
- zip
- autossh
- inetutils
- docker-compose

---
## Install Applications Required

- #### Install nrcon ( Ubuntu )

```bash
cd /opt

sudo apt-get update
sudo apt-get install gcc build-essential make

# Clone the repository
sudo git clone https://github.com/Tiiffi/mcrcon.git
cd /opt/mcrcon

sudo make
sudo make install

# Verify the installation
mcrcon -help
```

- #### Install nrcon ( Arch Linux )

```bash
cd /opt

sudo pacman -S gcc make git

# Clone the repository
sudo git clone https://github.com/Tiiffi/mcrcon.git
cd /opt/mcrcon

sudo make
sudo make install

# Verify the installation
mcrcon -help
```

---
## Setup and Installation

### Step 1: Create Project Directory 

```bash
sudo mkdir -p /var/www/minecraft-server/configurations
```

### Step 2: Set Directory Ownership
   
```bash
sudo chown -R $USER:$USER /var/www/minecraft-server
```

### Step 3: Clone the Repository
   
```bash
cd /var/www/minecraft-server/configurations
git clone https://github.com/luis122448/minecraft-server-bash.git
```

### Step 5: Add Forge Installer ( Optional )

Download the desired Minecraft Forge Installer JAR file from the official [minecraftforge](https://files.minecraftforge.net/net/minecraftforge/forge/)

Please the downloaded file into the `./server/` directory of the cloned repository and rename it to `forge-installer.jar`

```bash
cp /path/to/forge-*.**.*-**.*.**-installer.jar ./server/forge-installer.jar
```

**Important:** Ensure the Forge version you download is compatible with the Minecraft version you intend to use.

### Step 6: Add Your Mods

Place all your desired `mod.jar` files into the `./mods/` directory within the cloned repository.

```bash
# Example: Copy mods from a different location
cp /path/to/your/mods/*.jar /var/www/minecraft-server/configurations/mods/
```
**Important:** All mods must be compatible with the specific version of Minecraft Forge you are installing. Incompatible mods can cause the server to crash.

You can use the tree command to visualize the structure (optional):

```bash
tree ./mods

./mods
├── alexsmobs-1.22.8.jar
├── citadel-2.5.4-1.20.1.jar
├── Xaeros_Minimap_24.5.0_Forge_1.20.jar
├── XaerosWorldMap_1.39.0_Forge_1.20.jar
└── ...
```

### Step 7: Execute the Installation Script
    
Navigate to the project's configurations directory and run the `install.sh` script. 

```bash
cd /var/www/minecraft-server/configurations/
sudo bash ./install.sh -v <minecraft_version> -m <modpack_name> -t <server_type> -r <ram_server> -p <password>

# Example
sudo bash ./install.sh -v 1.20.1 -m survival -t vanilla -r 12G -p 941480149401
```

**Note:**
- `-v` `<minecraft_version>`: The target Minecraft version (e.g., 1.20.1, 1.20.6, 1.21.5). This must match the version of the forge-installer.jar you placed in ./server/.
- `-m` `<modpack_name>`: A name for your modpack (e.g., forge-custom, my-awesome-mods). Used for internal naming.
- `-t` `<server_type>`: The type of server (e.g., survival, creative).

---
## Local Deployment

### Run the Deployment Script

```bash
bash deploy.sh
```

### Check if the Docker container is running. Look for a container based on your project's image.
    
```bash
sudo docker ps
```

### Access the minecraft server on the source machine

```bash
localhost:$MINECRAFT_SERVER_APP_PORT
```

**Note** The Minecraft server application port `$MINECRAFT_SERVER_APP_PORT` and RCON port `$MINECRAFT_SERVER_RCON_PORT` must be open in the firewall of your remote server and potentially

### Access the minecraft server in local network

Execute the following command to get the local IP server `hostname -I`
Choice the IP address matching the local network, in my case `192.168.100.161`.
Connect to the Minecraft Server using the following address:

```bash
192.168.100.161:$MINECRAFT_SERVER_APP_PORT
```

### Access at cpnsole of the Minecraft Server
    
```bash
mcrcon -H $IP -P $MINECRAFT_SERVER_RCON_PORT -p $RCON_PASSWORD
```

**Note:** The `$IP` variable is the `IP` address of the server, review before step for more information.

---
## Server Deployment

For Server Deployment, this requires an virtual machine in cloud service, Recommended: AWS EC2 free tier.
AWS EC2 free tier: https://aws.amazon.com/ec2/

- Need open ports: $MINECRAFT_SERVER_APP_PORT, $MINECRAFT_SERVER_RCON_PORT
- Key.pem file

1. **Enable Port Forwarding and Gateway in SSH**

```bash
sudo nano /etc/ssh/ssh_config
```

```
AllowTcpForwarding yes
GatewayPorts yes
```

2. **Copy and paste key.pem in the following directory**
    
```bash
./ssh/key.pem
```

**Note:** The key.pem file is used to access the server via SSH.

3. **Initialize the SSH tunnel**
    
```bash
bash ./tunnel/start.sh
```

## Maintenance

1. **Backup the Minecraft Server**
    
```bash
bash backup.sh
```

**Note:** The backup is stored in the /var/www/minecraft-server/backups directory.
**Important:** This process stops the Minecraft Server.

2. **Restore the Minecraft Server**
    
```bash
bash restore.sh volume-DDMMYYYY-HHMMSS.zip
```

3. **Update mods collection**
    
Update the mods collection in the /var/www/minecraft-server/configurations/mods directory.
And execute the restart script.

```bash
bash restart.sh
```

**Note:** This proccess automatically generaction backup of the server.
**Important:** This process stops the Minecraft Server.