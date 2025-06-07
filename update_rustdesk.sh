#!/bin/bash

# Check if docker-compose.yml exists
if [ ! -f "rustdesk/docker-compose.yml" ]; then
    echo "docker-compose.yml file not found in rustdesk directory. Please run the installation script first."
    exit 1
fi

# Extract LAN IP from docker-compose.yml
RUSTDESK_IP=$(grep -oP '(?<=hbbs -r )\S+(?=:21117)' rustdesk/docker-compose.yml | head -n 1)
if [ -z "$RUSTDESK_IP" ]; then
    echo "Unable to extract LAN IP from docker-compose.yml. Please check the configuration file."
    exit 1
fi

echo "Using IP: $RUSTDESK_IP for RustDesk"

# Navigate to rustdesk directory
cd rustdesk || exit 1

# Store the current public key (if exists) for comparison
CURRENT_KEY=$(cat ./hbbs/id_ed25519.pub 2>/dev/null)

# Pull the latest RustDesk server image
echo "Pulling the latest RustDesk server image..."
sudo docker pull rustdesk/rustdesk-server:latest

# Restart RustDesk with the new image, preserving volumes
echo "Restarting RustDesk with the new version..."
sudo docker compose up -d

# Check the public key after update
NEW_KEY=$(cat ./hbbs/id_ed25519.pub 2>/dev/null)

# Compare public keys before and after
if [ "$CURRENT_KEY" != "$NEW_KEY" ] && [ -n "$NEW_KEY" ]; then
    echo "WARNING: Public key has changed after update. Please check and update clients accordingly."
    echo "New key: $NEW_KEY"
else
    echo "Public key remains unchanged after update."
fi

# Display update information
echo "Update completed. Check container status:"
sudo docker ps

# Display the current public key (whether changed or not)
echo "Current RustDesk Public Key:"
cat ./hbbs/id_ed25519.pub 2>/dev/null || echo "Public key not generated yet. Check container logs."

# Display client configuration instructions
echo -e "\nRustDesk Client Configuration Instructions (if needed):"
echo "1. Open RustDesk client"
echo "2. Go to Settings > Network"
echo "3. Ensure ID Server is: $RUSTDESK_IP"
echo "4. Paste the public key above into the Key field (if changed)"
echo "5. Save the configuration and connect"