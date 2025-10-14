#!/bin/bash
# ==============================
#  Google Chrome Remote Desktop Auto Installer
# ==============================

echo "=== 🔧 Menyiapkan sistem ==="
sudo apt update -y
sudo apt upgrade -y
sudo apt install wget curl unzip -y

echo "=== 🧩 Menginstal Google Chrome ==="
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb -y

echo "=== 🧩 Menginstal Chrome Remote Desktop ==="
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo apt install ./chrome-remote-desktop_current_amd64.deb -y

echo "=== 🖥️ Menginstal Desktop Environment XFCE (ringan) ==="
sudo DEBIAN_FRONTEND=noninteractive apt install xfce4 xfce4-goodies -y
sudo apt install xbase-clients -y

echo "exec /usr/bin/xfce4-session" > ~/.chrome-remote-desktop-session
sudo usermod -a -G chrome-remote-desktop $USER

echo
echo "✅ Sistem siap, sekarang tempel perintah dari Google Remote Desktop."
echo "Contoh:"
echo 'DISPLAY= /opt/google/chrome-remote-desktop/start-host --code="4/..." --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$(hostname)'
echo
read -p "Masukkan perintah lengkap di atas: " CMD

echo "=== 🚀 Menjalankan setup host ==="
PIN="123456"
bash -c "$CMD --pin=$PIN"

echo
echo "🎉 Selesai! Chrome Remote Desktop sudah dikonfigurasi."
echo "PIN default: 123456"
echo "Silakan buka https://remotedesktop.google.com/access untuk mengakses server ini."
