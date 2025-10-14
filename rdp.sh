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
apt install -y docker.io docker-compose vim curl wget

systemctl enable docker
systemctl start docker

echo
echo "=== 📂 Membuat direktori kerja dockercom ==="
mkdir -p /root/dockercom
cd /root/dockercom

echo
echo "=== 🧾 Membuat file windows11.yml ==="
cat > windows11.yml <<'EOF'
version: "3.9"

services:
  windows:
    image: dockurr/windows
    container_name: windows11
    environment:
      VERSION: "11"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "6G"
      CPU_CORES: "4"
      DISK_SIZE: "400G"
      DISK2_SIZE: "100G"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    restart: unless-stopped
    stop_grace_period: 2m
EOF

echo
echo "=== ✅ File windows11.yml berhasil dibuat ==="
cat windows11.yml

echo
echo "=== 🚀 Menjalankan Windows 11 container ==="
docker-compose -f windows11.yml up -d

echo
echo "=== 🎉 Selesai! Windows 11 sedang booting di container. ==="
echo "Gunakan Remote Desktop (RDP) untuk konek:"
echo "  ➤ Host/IP:  (ip address server kamu)"
echo "  ➤ Port:     3389"
echo "  ➤ Username: MASTER"
echo "  ➤ Password: admin@123"
echo
echo "Kamu juga bisa buka web console di port 8006 (http://<ip>:8006)"
echo
echo "Untuk melihat log boot Windows:"
echo "  sudo docker logs -f windows11"
echo
echo "Untuk menghentikan VM:"
echo "  sudo docker stop windows11"
