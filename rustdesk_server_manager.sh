#!/bin/bash

# Chọn ngôn ngữ / Language selection
LANG_CHOICE=1
select_language() {
  echo "Chọn ngôn ngữ / Select language / 選擇語言:"
  echo "1) Tiếng Việt"
  echo "2) English"
  echo "3) 繁體中文"
  read -rp "Lựa chọn / Choose [1-3]: " LANG_CHOICE
}
select_language

set_language() {
  case $LANG_CHOICE in
    2)
      MSG_INSTALL="Installing RustDesk server..."
      MSG_DONE="Done!"
      MSG_MENU=("Install RustDesk Server" "Update to latest version" "Restart / Fix errors" "Show Public Key" "Open Firewall Rules" "View Logs" "Exit")
      ;;
    3)
      MSG_INSTALL="正在安裝 RustDesk 伺服器..."
      MSG_DONE="完成！"
      MSG_MENU=("安裝 RustDesk 伺服器" "更新到最新版本" "重新啟動 / 修復錯誤" "顯示 Public Key" "開啟防火牆規則" "查看日誌" "退出")
      ;;
    *)
      MSG_INSTALL="Đang cài đặt RustDesk server..."
      MSG_DONE="Hoàn tất!"
      MSG_MENU=("Cài đặt RustDesk Server" "Cập nhật phiên bản mới" "Khởi động lại / sửa lỗi" "Hiển thị Public Key" "Mở Firewall" "Xem log" "Thoát")
      ;;
  esac
}
set_language

get_local_ip() {
  hostname -I | awk '{print $1}'
}

install_rustdesk() {
  echo "$MSG_INSTALL"
  apt update && apt install -y git curl ufw docker.io docker-compose

  mkdir -p ~/rustdesk-server && cd ~/rustdesk-server || exit
  git clone https://github.com/rustdesk/rustdesk-server.git . || git pull

  echo -e "\nChọn IP nội bộ hoặc nhập domain tùy chọn:"
  LOCAL_IP=$(get_local_ip)
  read -rp "Dùng IP mặc định [$LOCAL_IP] hoặc nhập domain: " DOMAIN_INPUT
  HOST_IP=${DOMAIN_INPUT:-$LOCAL_IP}

  mkdir -p data

  cat <<EOF > docker-compose-local.yml
version: "3.3"
services:
  hbbs:
    image: rustdesk/rustdesk-server:latest
    container_name: rustdesk-hbbs
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./data:/root
    command: hbbs -r $HOST_IP:21117

  hbbr:
    image: rustdesk/rustdesk-server:latest
    container_name: rustdesk-hbbr
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./data:/root
    command: hbbr
EOF

  docker-compose -f docker-compose-local.yml up -d
  echo "$MSG_DONE"
}

update_rustdesk() {
  cd ~/rustdesk-server || exit
  git pull
  docker-compose -f docker-compose-local.yml pull
  docker-compose -f docker-compose-local.yml up -d
  echo "$MSG_DONE"
}

restart_rustdesk() {
  cd ~/rustdesk-server || exit
  docker-compose -f docker-compose-local.yml restart
  echo "$MSG_DONE"
}

show_public_key() {
  docker exec rustdesk-hbbs cat /root/.ssh/id_ed25519.pub
}

open_firewall() {
  ufw allow 21114:21119/tcp
  ufw allow 21116/udp
  ufw --force enable
  echo "$MSG_DONE"
}

view_logs() {
  echo "1) rustdesk-hbbs"
  echo "2) rustdesk-hbbr"
  read -rp "Chọn dịch vụ: " SERVICE
  case $SERVICE in
    1) docker logs rustdesk-hbbs ;;
    2) docker logs rustdesk-hbbr ;;
    *) echo "Không hợp lệ / Invalid" ;;
  esac
}

main_menu() {
  while true; do
    echo -e "\n==== MENU ===="
    for i in "${!MSG_MENU[@]}"; do
      echo "$((i+1))) ${MSG_MENU[$i]}"
    done

    read -rp "Chọn: " CHOICE
    case $CHOICE in
      1) install_rustdesk ;;
      2) update_rustdesk ;;
      3) restart_rustdesk ;;
      4) show_public_key ;;
      5) open_firewall ;;
      6) view_logs ;;
      7) exit 0 ;;
      *) echo "Không hợp lệ / Invalid" ;;
    esac
  done
}

main_menu
