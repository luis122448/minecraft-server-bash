![Logo del Projecto](./resources/logo.png)

# Minecraft Forge Docker Server

This project is a Minecraft Forge Server that runs in a Docker container. The server is deployed on a remote server using an SSH tunnel. The project includes a deployment script that automates the deployment process.

## Requirements

- docker
- git
- tree
- zip
- autossh

## Installation

### Install Applications Required ( Ubuntu )

1.- **Install nrcon**

    ```bash
        cd /opt

        sudo apt-get update
        sudo apt-get install gcc 
        sudo apt-get install build-essential
        sudo apt-get install make

        git clone git clone https://github.com/Tiiffi/mcrcon.git

        cd /opt/mcrcon
        make
        sudo make install
    ```

### Install the Minecraft Server

1. **Create a new directory**

    ```bash
        sudo mkdir /var/www/minecraft-server

        sudo mkdir /var/www/minecraft-server/configurations
    ```

2. **Change the owner of the directory**
   
    ```bash
        sudo chown -R $USER:$USER /var/www/minecraft-server
    ```

3. **Clone the repository**
   
    ```bash
        cd /var/www/minecraft-server/configurations

        git clone git@github.com:luis122448/minecraft-server-bash.git
    ```

4. **Define the environment variables**

    First, define the IP address of the server for $SERVER_LOCAL_HOST variable:
    
    ```bash
        ip -4 addr show docker0 | grep -Po 'inet \K[\d.]+' 
    ```

    Then, define the environment variables in /etc/environment:

    ```bash
        sudo nano /etc/environment
    ```

    ```bash
        SERVER_LOCAL_HOST=
        SERVER_LOCAL_USER=
        SERVER_HOST= # Only required for server deployment
        SERVER_USER= # Only required for server deployment
        RCON_PASSWORD=
        MINECRAFT_SERVER_APP_PORT=25565 # Default Minecraft Server Port
        MINECRAFT_SERVER_RCON_PORT=25575 # Default Minecraft Server RCON Port
    ```

    Charge the environment variables:

    ```bash
        source /etc/environment
    ```

    **Note:** The $SERVER_HOST and $SERVER_USER variables are used to access the server via SSH.

5. **Copy and Paste forge-installer.jar installer in the following directory**

    ```bash
        cp /path/to/forge-*.**.*-**.*.**-installer.jar ./server/forge-installer.jar
    ```

    **Note:** The forge.jar installer is used to install the Minecraft Forge Server. Check the version of the forge.jar installer in the official website: https://files.minecraftforge.net/ ( Example: forge-1.20.6-50.1.20-installer.jar )

    **Important:** Rename forge installer to forge-installer.jar

6. **Copy and Paste your mods collection in the following directory**

    ```bash
        ./mods
    ```

    **Important:** The mods collection must match the version of the Minecraft Forge Server.

    **Example:** 

    ```bash
        tree ./mods

        ./mods
        ├── alexsmobs-1.22.8.jar
        ├── citadel-2.5.4-1.20.1.jar
        ├── Xaeros_Minimap_24.5.0_Forge_1.20.jar
        ├── XaerosWorldMap_1.39.0_Forge_1.20.jar
        └── ...
    ```

7. **Execute the installation script**
    
    ```bash
        bash install.sh *.**.*
    ```

    **Note:** The *.*.* version is the version of the Minecraft Forge Server. ( Example: 1.20.1 )
    **Important:** This version must match the version of the forge-installer.jar installer.

## Local Deployment

1. **Execute the deployment script**
    
    ```bash
        bash deploy.sh
    ```

2. **Verify the deployment**
    
    ```bash
        sudo docker ps
    ```

3. **Local IP Server**

    1. **Access the minecraft server on the source machine**

    ```bash
        localhost:$MINECRAFT_SERVER_APP_PORT
    ```

    2. **Access the minecraft server in local network**
   
    Execute the following command to get the local IP server:

    ```bash
        hostname -I
    ```

    Choice the IP address matching the local network, in my case 192.168.100.***.

    Connect to the Minecraft Server using the following address:

    ```bash
        192.168.100.***:$MINECRAFT_SERVER_APP_PORT
    ```

4. **Access at cpnsole of the Minecraft Server**
    
    ```bash
        mcrcon -H $IP -P $MINECRAFT_SERVER_RCON_PORT -p $RCON_PASSWORD
    ```

    **Note:** The $IP variable is the IP address of the server, review step 3 for more information.

## Server Deployment

For Server Deployment, this requires an virtual machine in cloud service, Recommended: AWS EC2 free tier.
AWS EC2 free tier: https://aws.amazon.com/ec2/

- Need open ports: $MINECRAFT_SERVER_APP_PORT, $MINECRAFT_SERVER_RCON_PORT
- Key.pem file

1. **Copy and paste key.pem in the following directory**
    
    ```bash
        ./tunnel/key.pem
    ```

    **Note:** The key.pem file is used to access the server via SSH.

2. **Initialize the SSH tunnel**
    
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