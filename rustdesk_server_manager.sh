#!/bin/bash

# ==================== CẤU HÌNH NGÔN NGỮ ====================
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
      LANG_INSTALL_MSG="Installing RustDesk server..."
      LANG_DONE_MSG="Done!"
      LANG_MENU_TITLE="Main Menu"
      LANG_MENU_OPTIONS=(
        "Install RustDesk Server"
        "Update to latest version"
        "Restart / Fix errors"
        "Show Public Key"
        "Open Firewall Rules"
        "View Logs"
        "Exit"
      )
      ;;
    3)
      LANG_INSTALL_MSG="正在安裝 RustDesk 伺服器..."
      LANG_DONE_MSG="完成！"
      LANG_MENU_TITLE="主選單"
      LANG_MENU_OPTIONS=(
        "安裝 RustDesk 伺服器"
        "更新到最新版本"
        "重新啟動 / 修復錯誤"
        "顯示 Public Key"
        "開啟防火牆規則"
        "查看日誌"
        "退出"
      )
      ;;
    *)
      LANG_INSTALL_MSG="Đang cài đặt RustDesk server..."
      LANG_DONE_MSG="Hoàn tất!"
      LANG_MENU_TITLE="Menu chính"
      LANG_MENU_OPTIONS=(
        "Cài đặt RustDesk Server"
        "Cập nhật phiên bản mới"
        "Khởi động lại / sửa lỗi"
        "Hiển thị Public Key"
        "Mở Firewall"
        "Xem log"
        "Thoát"
      )
      ;;
  esac
}

set_language

# ==================== HÀM CHÍNH ====================
install_rustdesk() {
  echo "$LANG_INSTALL_MSG"
  sudo apt update
  sudo apt install -y docker.io docker-compose git ufw

  mkdir -p ~/rustdesk-server && cd ~/rustdesk-server || exit
  git clone https://github.com/rustdesk/rustdesk-server.git .

  echo "\nChọn IP nội bộ hoặc nhập domain tùy chọn:"
  LOCAL_IP=$(hostname -I | awk '{print $1}')
  read -rp "Dùng IP mặc định [$LOCAL_IP] hoặc nhập domain: " INPUT_DOMAIN
  DOMAIN_OR_IP=${INPUT_DOMAIN:-$LOCAL_IP}

  cat > docker-compose-local.yml <<EOF
version: '3.8'
services:
  hbbs:
    image: rustdesk/rustdesk-server:latest
    container_name: rustdesk-hbbs
    restart: always
    network_mode: host
    volumes:
      - ./data:/root
    command: hbbs -k _

  hbbr:
    image: rustdesk/rustdesk-server:latest
    container_name: rustdesk-hbbr
    restart: always
    network_mode: host
    volumes:
      - ./data:/root
    command: hbbr
EOF

  docker-compose -f docker-compose-local.yml up -d
  echo "$LANG_DONE_MSG"
}

update_rustdesk() {
  cd ~/rustdesk-server || exit
  git pull
  docker-compose -f docker-compose-local.yml down
  docker-compose -f docker-compose-local.yml pull
  docker-compose -f docker-compose-local.yml up -d
}

restart_rustdesk() {
  docker-compose -f ~/rustdesk-server/docker-compose-local.yml restart
}

show_public_key() {
  docker exec rustdesk-hbbs cat /root/.ssh/id_ed25519.pub
}

open_firewall() {
  sudo ufw allow 21114:21119/tcp
  sudo ufw allow 21116/udp
  sudo ufw --force enable
}

view_logs() {
  echo "1) rustdesk-hbbs"
  echo "2) rustdesk-hbbr"
  read -rp "Chọn dịch vụ (1-2): " log_choice
  case $log_choice in
    1) docker logs -f rustdesk-hbbs;;
    2) docker logs -f rustdesk-hbbr;;
    *) echo "Lựa chọn không hợp lệ";;
  esac
}

main_menu() {
  while true; do
    echo "\n===== ${LANG_MENU_TITLE} ====="
    for i in "${!LANG_MENU_OPTIONS[@]}"; do
      echo "$((i+1))) ${LANG_MENU_OPTIONS[$i]}"
    done
    read -rp "Chọn một tuỳ chọn: " choice
    case $choice in
      1) install_rustdesk;;
      2) update_rustdesk;;
      3) restart_rustdesk;;
      4) show_public_key;;
      5) open_firewall;;
      6) view_logs;;
      7) exit;;
      *) echo "Lựa chọn không hợp lệ.";;
    esac
  done
}

main_menu
