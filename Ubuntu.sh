#!/usr/bin/env bash
set -euo pipefail

# Auto installer: Ubuntu XFCE + Chrome Remote Desktop + VS Code + dev tools
# - Run as a normal user with sudo privileges
# - Tested on Ubuntu 22.04/20.04
# Usage:
#   chmod +x auto-crd-setup.sh
#   ./auto-crd-setup.sh

DEFAULT_TOKEN="4/0AVGzR1CQ7xd08WjNkoCYnTGwggVua8IBUceuCa9SuPi2dDQ-hQy7CchI9eNRh3HIKJuLVw"

echo "=== Auto CRD + Ubuntu Desktop + VSCode + Dev Tools installer ==="
echo
# Check sudo
if ! sudo -n true 2>/dev/null; then
  echo "Pastikan kamu dapat menjalankan sudo (enter password akan diminta)."
fi

read -r -p "Masukkan token CRD (ENTER untuk pakai default): " input_token
if [ -z "$input_token" ]; then
  CRD_TOKEN="$DEFAULT_TOKEN"
else
  CRD_TOKEN="$input_token"
fi

# validate token rudimenter
if [[ ! "$CRD_TOKEN" =~ ^4/ ]]; then
  echo "Peringatan: token tampaknya tidak diawali '4/'. Lanjutkan? (y/N)"
  read -r choice
  if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "Dibatalkan."
    exit 1
  fi
fi

# Prompt for PIN
while true; do
  read -r -p "Masukkan PIN untuk CRD (6-12 digit): " CRD_PIN
  if [[ "$CRD_PIN" =~ ^[0-9]{6,12}$ ]]; then
    break
  else
    echo "PIN tidak valid. Harus 6–12 digit."
  fi
done

HOSTNAME="$(hostname)"
REDIRECT_URL="https://remotedesktop.google.com/_/oauthredirect"

echo
echo "Token: $CRD_TOKEN"
echo "Hostname akan diregistrasi sebagai: $HOSTNAME"
echo

# Update & basic packages
echo "1) Update dan install paket dasar..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  wget \
  gnupg \
  lsb-release \
  software-properties-common \
  build-essential \
  git \
  python3 \
  python3-pip \
  unzip \
  net-tools

# Install XFCE desktop (lightweight)
echo "2) Install XFCE desktop (lightweight)"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y xfce4 xfce4-goodies

# Install Chrome Remote Desktop (download .deb and install)
echo "3) Install Chrome Remote Desktop package..."
TMP_DEB="$(mktemp -u)/chrome-remote-desktop_current_amd64.deb"
TMP_DIR="$(mktemp -d)"
cd "$TMP_DIR"
echo "Downloading chrome-remote-desktop..."
wget -q -O chrome-remote-desktop_current_amd64.deb "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb" || {
  echo "Gagal mengunduh paket Chrome Remote Desktop. Periksa koneksi."
  exit 1
}
sudo dpkg -i chrome-remote-desktop_current_amd64.deb || sudo apt-get -f install -y
cd - >/dev/null || true
rm -rf "$TMP_DIR"

# Configure a lightweight session for CRD: use XFCE
echo "4) Mengatur session desktop untuk Chrome Remote Desktop (XFCE)"
mkdir -p "${HOME}/.chrome-remote-desktop-session"
cat > "${HOME}/.chrome-remote-desktop-session" <<'EOF'
#!/bin/bash
# Start XFCE session
exec /usr/bin/startxfce4
EOF
chmod +x "${HOME}/.chrome-remote-desktop-session"

# Install VS Code (stable .deb)
echo "5) Install Visual Studio Code..."
wget -qO /tmp/vscode.deb "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
sudo dpkg -i /tmp/vscode.deb || sudo apt-get -f install -y
rm -f /tmp/vscode.deb

# Install Node.js (LTS) and npm
echo "6) Install Node.js LTS"
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker (optional but handy)
echo "7) Install Docker (docker.io) and docker-compose-plugin"
sudo apt-get install -y docker.io docker-compose-plugin
# Add current user to docker group (so you can run docker without sudo)
sudo usermod -aG docker "$USER" || true

# Extra useful dev tools
echo "8) Install additional developer utilities (fd, ripgrep, tmux)..."
sudo apt-get install -y ripgrep fd-find tmux

# Clean up
sudo apt-get autoremove -y
sudo apt-get clean -y

# Register Chrome Remote Desktop host (headless)
echo
echo "9) Mendaftarkan host ke Chrome Remote Desktop..."
# The start-host script reads from stdin for PIN entry; we'll try to feed PIN twice (confirm)
CRD_CMD="/opt/google/chrome-remote-desktop/start-host --code=\"${CRD_TOKEN}\" --redirect-url=\"${REDIRECT_URL}\" --name=\"${HOSTNAME}\""
echo "Menjalankan: $CRD_CMD"
echo
# Run the registration command as the current user (not root). Try feeding the PIN.
# Some versions prompt for PIN confirmation; we provide PIN twice separated by newline.
# Use setsid to ensure the process is attached to a pseudo-tty so the program reads stdin.
# If automatic piping fails, we'll show the full command for manual run.
if setsid bash -c "printf '%s\n%s\n' \"${CRD_PIN}\" \"${CRD_PIN}\" | ${CRD_CMD}" ; then
  echo "✅ Perintah registrasi Chrome Remote Desktop selesai (mungkin sukses)."
else
  echo "⚠️ Upaya otomatis untuk mengisi PIN gagal. Silakan jalankan perintah registrasi manual ini (copy-paste):"
  echo
  echo "  ${CRD_CMD}"
  echo
  echo "Lalu masukkan PIN ketika diminta: ${CRD_PIN}"
fi

echo
echo "10) Mengaktifkan service chrome-remote-desktop (systemwide)..."
# Enable (the package normally installs systemd services); restart service to be safe
sudo systemctl enable chrome-remote-desktop@$USER.service --now || true
# Note: the service name may differ; the host should appear in remotedesktop.google.com/access once registration completes.

echo
echo "Selesai. Beberapa catatan penting:"
echo "- Buka https://remotedesktop.google.com/access untuk melihat host dan mengakses desktop."
echo "- Jika host tidak muncul segera, tunggu beberapa menit atau restart mesin."
echo "- Jika registrasi gagal, jalankan perintah registrasi manual tadi di terminal (gunakan token yang diberikan)."
echo "- Kamu mungkin perlu logout/login atau restart agar docker group membership berlaku (jika install Docker)."
echo
echo "Installed summary:"
echo " - Desktop: XFCE"
echo " - Chrome Remote Desktop: installed"
echo " - VS Code: installed (code)"
echo " - Node.js, npm, Python3, pip, git, build-essential, docker"
echo
echo "Happy remoting! 🚀"
