#!/bin/bash
# ============================================
# 🚀 Auto Installer: Ubuntu GUI + NoVNC + Cloudflare Tunnel
# ============================================

set -e

echo "=== 🔧 Menjalankan sebagai root ==="
if [ "$EUID" -ne 0 ]; then
  echo "Script ini butuh akses root. Jalankan dengan: sudo bash install-novnc-cloudflare.sh"
  exit 1
fi

echo
echo "=== 📦 Update & install komponen dasar ==="
apt update -y
apt install -y xfce4 xfce4-goodies tightvncserver git python3-websockify python3-numpy curl wget unzip

echo
echo "=== 🧾 Membuat user desktop ==="
if ! id "ubuntu" &>/dev/null; then
  useradd -m -s /bin/bash ubuntu
  echo "ubuntu:ubuntu123" | chpasswd
  echo "User 'ubuntu' dibuat dengan password 'ubuntu123'"
else
  echo "User 'ubuntu' sudah ada, lanjut..."
fi

echo
echo "=== 🧰 Setup TightVNC Server ==="
su - ubuntu -c "vncserver -geometry 1280x720"
su - ubuntu -c "vncserver -kill :1"

cat > /home/ubuntu/.vnc/xstartup <<'EOF'
#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &
EOF

chmod +x /home/ubuntu/.vnc/xstartup
chown -R ubuntu:ubuntu /home/ubuntu/.vnc

echo
echo "=== ▶️ Jalankan ulang VNC server ==="
su - ubuntu -c "vncserver :1"

echo
echo "=== 🌐 Clone NoVNC & Websockify ==="
if [ ! -d "/opt/noVNC" ]; then
  cd /opt
  git clone https://github.com/novnc/noVNC.git
  git clone https://github.com/novnc/websockify.git
fi

echo
echo "=== 🚀 Jalankan NoVNC di port 6080 ==="
cd /opt/noVNC
nohup ./utils/launch.sh --vnc localhost:5901 --listen 6080 >/var/log/novnc.log 2>&1 &

echo
echo "=== ☁️ Install Cloudflare Tunnel ==="
if [ ! -f "/usr/local/bin/cloudflared" ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

echo
echo "=== 🌍 Membuat tunnel publik untuk NoVNC ==="
nohup cloudflared tunnel --url http://localhost:6080 > /var/log/cloudflared.log 2>&1 &
sleep 5

CF_URL=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" /var/log/cloudflared.log | head -n 1)

echo
echo "=============================================="
echo "🎉 Instalasi Selesai!"
echo
if [ -n "$CF_URL" ]; then
  echo "🖥️  Akses GUI Ubuntu kamu di browser:"
  echo "🌍 URL:  ${CF_URL}/vnc.html"
else
  echo "⚠️ Tidak bisa mendeteksi URL Cloudflare."
  echo "Lihat log dengan perintah:  tail -f /var/log/cloudflared.log"
fi
echo
echo "👤 Login Ubuntu:  ubuntu"
echo "🔑 Password:      ubuntu123"
echo
echo "Untuk menghentikan server:"
echo "  su - ubuntu -c 'vncserver -kill :1'"
echo "  pkill -f websockify"
echo "  pkill -f cloudflared"
echo
echo "Untuk melihat log:"
echo "  tail -f /var/log/novnc.log"
echo "  tail -f /var/log/cloudflared.log"
echo
echo "=== ✅ Selesai! Nikmati Ubuntu GUI di browser ==="
echo "=============================================="
