#!/bin/bash
set -euo pipefail

echo "=== 🚀 Pterodactyl Auto Installer ==="
echo "Memeriksa Docker dan Docker Compose..."

# Cek docker
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ Docker belum terinstal. Menginstal..."
  apt update && apt install -y 
fi

# Cek docker-compose
if ! command -v docker-compose >/dev/null 2>&1; then
  echo "❌ Docker Compose belum terinstal. Menginstal..."
  apt install docker-compose -y
fi

# Buat file docker-compose.yml otomatis
echo "🧱 Membuat file docker-compose.yml ..."
cat > docker-compose.yml <<'EOF'
version: "3.4"

services:
  database:
    image: mariadb:10.11
    restart: always
    environment:
      MYSQL_DATABASE: panel
      MYSQL_USER: pterodactyl
      MYSQL_PASSWORD: thisisthepasswordforpterodactyl
      MYSQL_ROOT_PASSWORD: rootpass
    volumes:
      - db:/var/lib/mysql

  cache:
    image: redis:7
    restart: always

  php-fpm:
    image: yoshiwalsh/pterodactyl-panel:v1.11.10
    restart: always
    depends_on:
      - database
      - cache
    environment:
      DB_HOST: database
      DB_PORT: 3306
      DB_DATABASE: panel
      DB_USERNAME: pterodactyl
      DB_PASSWORD: thisisthepasswordforpterodactyl
      APP_ENV: production
      APP_URL: "http://${CODESPACE_NAME:-localhost}:5080"
    volumes:
      - app:/var/www/html/
      - storage:/var/www/html/storage/
      - public:/var/www/html/public/

  nginx:
    image: yoshiwalsh/nginx-for-php-fpm
    restart: always
    depends_on:
      - php-fpm
    ports:
      - 5080:80
    volumes:
      - public:/var/www/html/

volumes:
  public:
  db:
  storage:
  app:
EOF

echo "✅ docker-compose.yml dibuat."

# Jalankan container
echo "📦 Menjalankan Docker Compose..."
docker-compose up -d

echo "⏳ Menunggu container siap..."
sleep 25

# Ambil nama container PHP-FPM
PHP_FPM_CONTAINER=$(docker ps --format '{{.Names}}' | grep php-fpm || true)
if [ -z "$PHP_FPM_CONTAINER" ]; then
  echo "❌ Gagal menemukan container php-fpm."
  docker ps
  exit 1
fi

echo "🧩 Container PHP-FPM ditemukan: $PHP_FPM_CONTAINER"

# Generate APP_KEY dan migrasi
echo "🔑 Menghasilkan APP_KEY dan migrasi database..."
docker exec -i $PHP_FPM_CONTAINER php artisan key:generate --force || true
sleep 2
docker exec -i $PHP_FPM_CONTAINER php artisan migrate --force

# Buat user admin otomatis
echo "👤 Membuat user admin default: NICKY / NICKY"
docker exec -i $PHP_FPM_CONTAINER php artisan p:user:make <<'EOF'
NICKY
nicky@example.com
NICKY
NICKY
yes
EOF

echo "✅ User admin berhasil dibuat."

# Tampilkan URL Panel
CODESPACE_NAME=${CODESPACE_NAME:-localhost}
GITHUB_DOMAIN=${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-"127.0.0.1.nip.io"}
PANEL_URL="http://${CODESPACE_NAME}:5080"

echo ""
echo "🎉 Instalasi selesai!"
echo "🌐 Akses Panel di: $PANEL_URL"
echo "🔑 Login:"
echo "   Username: NICKY"
echo "   Password: NICKY"
echo ""
echo "Jika berjalan di GitHub Codespace, link akan otomatis diforward ke domain codespace kamu."
