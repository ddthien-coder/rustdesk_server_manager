#!/bin/bash

# Function to get LAN IP automatically
get_lan_ip() {
    ip addr show | grep -E 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1
}

# Check for custom IP provided as argument
if [ -z "$1" ]; then
    RUSTDESK_IP=$(get_lan_ip)
    if [ -z "$RUSTDESK_IP" ]; then
        echo "Could not detect LAN IP automatically. Please provide a LAN IP."
        read -p "Enter LAN IP (e.g., 192.168.1.100): " RUSTDESK_IP
    fi
else
    RUSTDESK_IP="$1"
fi

echo "Using IP: $RUSTDESK_IP for RustDesk"

# Update system and install Docker
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Create directory and docker-compose.yml for RustDesk
mkdir -p rustdesk && cd rustdesk
cat <<EOF > docker-compose.yml
networks:
  rustdesk-net:
    external: false
services:
  hbbs:
    container_name: hbbs
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r $RUSTDESK_IP:21117 -k _
    volumes:
      - ./hbbs:/root
    networks:
      - rustdesk-net
    depends_on:
      - hbbr
    restart: unless-stopped
  hbbr:
    container_name: hbbr
    ports:
      - 21117:21117
      - 21119:21119
    image: rustdesk/rustdesk-server:latest
    command: hbbr -k _
    volumes:
      - ./hbbr:/root
    networks:
      - rustdesk-net
    restart: unless-stopped
EOF

# Stop and remove existing containers if they exist
sudo docker compose down || true

# Start RustDesk
sudo docker compose up -d

# Display public key
echo "RustDesk Public Key:"
cat ./hbbs/id_ed25519.pub 2>/dev/null || echo "Public key not generated yet. Check container logs."

# Display client configuration instructions
echo -e "\nIT INFRA"