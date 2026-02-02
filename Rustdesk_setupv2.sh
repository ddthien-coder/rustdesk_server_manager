#!/bin/bash

# Your configuration information
LAN_IP=""
PUBLIC_IP=""
DATA_DIR="./data"

echo "Setting up RustDesk Server with Static IP: $PUBLIC_IP"

# 1. Update your system and install Docker (keep logic)
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER

#2. Create a working directory
mkdir -p rustdesk/data && cd rustdesk

# 3. Create an optimized docker-compose.yml file
# Important: The -r parameter must point to the Public IP address so that clients outside the network can see the Relay Server
cat <<EOF > docker-compose.yml
networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r $PUBLIC_IP:21117 -k _
    volumes:
      - $DATA_DIR:/root
    networks:
      - rustdesk-net
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    command: hbbr -k _
    volumes:
      - $DATA_DIR:/root
    networks:
      - rustdesk-net
    ports:
      - 21117:21117
      - 21119:21119
    restart: unless-stopped
EOF

#4. Start the service
sudo docker compose down || true
sudo docker compose up -d

#5. Automatically obtain the Public Key to configure the Client.
sleep 5
PUB_KEY=$(sudo cat $DATA_DIR/id_ed25519.pub)

echo -e "\n========================================================"
echo -e "RUSTDESK CLIENT CONFIGURATION INFORMATION (REMOTE CONTROL REQUIRED):"
echo -e "ID Server: $PUBLIC_IP"
echo -e "Relay Server: $PUBLIC_IP"
echo -e "API Server: (Empty)"
echo -e "Key: $PUB_KEY"
echo -e "========================================================\n"
