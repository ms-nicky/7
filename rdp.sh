#!/bin/bash
# ============================================
# 🚀 Auto Installer: Windows 11 on Docker (dockurr/windows)
# ============================================

set -e

echo "=== 🔧 Menjalankan sebagai root ==="
if [ "$EUID" -ne 0 ]; then
  echo "Script ini butuh akses root. Jalankan dengan: sudo bash install-windows11.sh"
  exit 1
fi

echo "=== 📦 Update & Install Docker Compose ==="
apt update -y
apt install docker-compose -y

systemctl enable docker
systemctl start docker

echo
echo "=== 📂 Membuat direktori kerja dockercom ==="
mkdir -p /root/dockercom
cd /root/dockercom

echo
echo "=== 🧾 Membuat file windows.yml ==="
cat > windows.yml <<'EOF'
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "11"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    volumes:
      - ./windows:/storage
    restart: always
    stop_grace_period: 2m
EOF

echo
echo "=== ✅ File windows11.yml berhasil dibuat ==="
cat windows.yml

echo
echo "=== 🚀 Menjalankan Windows 11 container ==="
docker-compose -f windows.yml up -d

echo
echo "=== 🎉 Selesai! Windows sedang booting di container. ==="
echo "Gunakan Remote Desktop (RDP) untuk konek:"
echo "  ➤ Host/IP:  (ip address server kamu)"
echo "  ➤ Port:     3389"
echo "  ➤ Username: MASTER"
echo "  ➤ Password: admin@123"
echo
echo "Kamu juga bisa buka web console di port 8006 (http://<ip>:8006)"
echo
echo "Untuk melihat log boot Windows:"
echo "  sudo docker logs -f windows"
echo
echo "Untuk menghentikan VM:"
echo "  sudo docker stop windows"
