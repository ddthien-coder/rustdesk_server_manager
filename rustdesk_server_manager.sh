#!/bin/bash

# Ngôn ngữ mặc định: Tiếng Việt
LANG_CHOICE=1

select_language() {
  echo "Chọn ngôn ngữ / Select language / 選擇語言:"
  echo "1) Tiếng Việt"
  echo "2) English"
  echo "3) 繁體中文"
  read -rp "Lựa chọn / Choose [1-3]: " LANG_CHOICE
}

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

# Hàm hiển thị menu và xử lý lựa chọn
main_menu() {
  while true; do
    echo "============================"
    echo "${LANG_MENU_TITLE}"
    echo "============================"

    for i in "${!LANG_MENU_OPTIONS[@]}"; do
      printf "%d) %s\n" "$((i+1))" "${LANG_MENU_OPTIONS[$i]}"
    done

    read -rp "Chọn / Choose: " choice

    case $choice in
      1) install_rustdesk;;
      2) update_rustdesk;;
      3) restart_rustdesk;;
      4) show_public_key;;
      5) open_firewall;;
      6) view_logs;;
      7) exit 0;;
      *) echo "Lựa chọn không hợp lệ / Invalid choice / 無效選項";;
    esac
  done
}

# Cài đặt RustDesk server
install_rustdesk() {
  echo "$LANG_INSTALL_MSG"
  apt update && apt install -y docker.io docker-compose git ufw
  systemctl enable --now docker

  mkdir -p ~/rustdesk-server && cd ~/rustdesk-server
  git clone https://github.com/rustdesk/rustdesk-server.git .

  echo "Chọn IP nội bộ hoặc nhập domain tuỳ chọn:"
  IP=$(hostname -I | awk '{print $1}')
  read -rp "Dùng IP mặc định [$IP] hoặc nhập domain: " input_ip
  SERVER_ADDR=${input_ip:-$IP}

  cat > docker-compose-local.yml <<EOF
version: '3.8'
services:
  hbbs:
    image: rustdesk/rustdesk-server:latest
    container_name: rustdesk-hbbs
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21117:21117
      - 21118:21118
      - 21119:21119
    command: hbbs -r $SERVER_ADDR:21117
    volumes:
      - ./data:/root
  hbbr:
    image: rustdesk/rustdesk-server:latest
    container_name: rustdesk-hbbr
    ports:
      - 21114:21114
    command: hbbr
    volumes:
      - ./data:/root
EOF

  docker compose -f docker-compose-local.yml up -d
  echo "$LANG_DONE_MSG"
  show_public_key
}

# Cập nhật
update_rustdesk() {
  cd ~/rustdesk-server || exit
  git pull
  docker compose -f docker-compose-local.yml up -d --build
  echo "$LANG_DONE_MSG"
}

# Khởi động lại
restart_rustdesk() {
  docker compose -f ~/rustdesk-server/docker-compose-local.yml restart
  echo "$LANG_DONE_MSG"
}

# Hiển thị Public Key
show_public_key() {
  echo "Public Key:"
  docker exec rustdesk-hbbs cat /root/id_ed25519.pub || echo "Không tìm thấy key"
}

# Mở Firewall
open_firewall() {
  ufw allow 21114/tcp
  ufw allow 21115/tcp
  ufw allow 21116/tcp
  ufw allow 21116/udp
  ufw allow 21117/tcp
  ufw allow 21118/tcp
  ufw allow 21119/tcp
  ufw --force enable
  echo "$LANG_DONE_MSG"
}

# Xem logs
view_logs() {
  echo "1) rustdesk-hbbs"
  echo "2) rustdesk-hbbr"
  read -rp "Chọn service để xem log: " log_choice
  case $log_choice in
    1) docker logs -f rustdesk-hbbs;;
    2) docker logs -f rustdesk-hbbr;;
    *) echo "Lựa chọn không hợp lệ";;
  esac
}

# Khởi động chương trình
select_language
set_language
main_menu
