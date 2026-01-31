#!/bin/bash

# Thông tin cấu hình của bạn
LAN_IP=""
PUBLIC_IP=""
DATA_DIR="./data"

echo "Đang thiết lập RustDesk Server với IP Tĩnh: $PUBLIC_IP"

# 1. Cập nhật hệ thống và cài đặt Docker (giữ nguyên logic của bạn)
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER

# 2. Tạo thư mục làm việc
mkdir -p rustdesk/data && cd rustdesk

# 3. Tạo file docker-compose.yml tối ưu
# Quan trọng: Tham số -r phải trỏ về IP Public để Client ngoài mạng có thể thấy Relay Server
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

# 4. Khởi động dịch vụ
sudo docker compose down || true
sudo docker compose up -d

# 5. Lấy Public Key tự động để cấu hình Client
sleep 5
PUB_KEY=$(sudo cat $DATA_DIR/id_ed25519.pub)

echo -e "\n========================================================"
echo -e "THÔNG TIN CẤU HÌNH RUSTDESK CLIENT (MÁY CẦN REMOTE):"
echo -e "ID Server: $PUBLIC_IP"
echo -e "Relay Server: $PUBLIC_IP"
echo -e "API Server: (Để trống)"
echo -e "Key: $PUB_KEY"
echo -e "========================================================\n"
