
# Install Rustdesk Server | INFRA TEAM
## How to Use the Script
-Download script from github to your host. 

    wget https://raw.githubusercontent.com/ddthien-coder/rustdesk_server_manager/refs/heads/master/install_rustdesk.sh
    

-Make it executable:

    chmod +x install_rustdesk.sh

-Run the script:

   Automatically detect LAN IP:
      
    ./install_rustdesk.sh.

    The script will detect the server's LAN IP (excluding 127.0.0.1). If it fails to detect, it will prompt you to enter an IP.

-Specify a custom IP:

    ./install_rustdesk.sh 10.1.32.63
    
    Replace 10.1.32.63 with your desired LAN IP.:

-Output:

    The script installs Docker, creates a docker-compose.yml file with the chosen IP, starts the RustDesk server, and displays the public key along with client configuration instructions.
       
-Notes

    Firewall: If using UFW or another firewall, ensure the required ports are open:
    sudo ufw allow 21115
    sudo ufw allow 21116
    sudo ufw allow 21116/udp
    sudo ufw allow 21117
    sudo ufw allow 21118
    sudo ufw allow 21119
Static IP: If your server uses DHCP, the LAN IP may change. Consider setting a static IP to avoid updating the configuration.

-Check containers:

    sudo docker ps
-View logs if there are issues:

    sudo docker logs hbbs
    sudo docker logs hbbr

Access from outside LAN: To access RustDesk from the Internet, configure NAT/Port Forwarding on your router or use a domain with a reverse proxy

Write: INFRA TEAM 2025/06