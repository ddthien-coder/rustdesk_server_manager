#!/bin/bash

# Hàm lấy IP LAN tự động
get_lan_ip() {
    ip addr show | grep -E 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1
}

# Kiểm tra tham số dòng lệnh để lấy IP tùy chỉnh
if [ -z "$1" ]; then
    RUSTDESK_IP=$(get_lan_ip)
    if [ -z "$RUSTDESK_IP" ]; then
        echo "Không thể tự động lấy IP LAN. Vui lòng cung cấp IP LAN."
        read -p "Nhập IP LAN (ví dụ: 192.168.1.100): " RUSTDESK_IP
    fi
else
    RUSTDESK_IP="$1"
fi

echo "Sử dụng IP: $RUSTDESK_IP cho RustDesk"

# Cập nhật hệ thống và cài đặt Docker
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Tạo thư mục và file docker-compose.yml cho RustDesk
mkdir -p rustdesk && cd rustdesk
cat <<EOF > docker-compose.yml
version: '3'
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

# Khởi động RustDesk
sudo docker compose up -d

# Hiển thị khóa công khai
echo "Khóa công khai RustDesk:"
cat ./hbbs/id_ed25519.pub

# Hiển thị hướng dẫn cấu hình client
echo -e "\nHướng dẫn cấu hình RustDesk Client:"
echo "1. Tải RustDesk client từ https://rustdesk.com/"
echo "2. Vào Settings > Network"
echo "3. Nhập ID Server: $RUSTDESK_IP"
echo "4. Dán khóa công khai ở trên vào trường Key"
echo "5. Lưu cấu hình và kết nối"