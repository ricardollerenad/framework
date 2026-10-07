#!/usr/bin/env bash
###############################################################################
# scripts/02_deploy.sh — Despliegue en un VPS Debian/Ubuntu con dominio y HTTPS
# Uso (desde cualquier carpeta, con tu usuario NORMAL que tenga sudo):
#     ./scripts/02_deploy.sh
# Requisitos: el DNS del dominio ya apunta a este servidor (registro A).
###############################################################################
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
PROJECT_DIR="$(pwd)"

if [ "$(id -u)" -eq 0 ]; then
  echo "❌ No lo ejecutes como root ni con sudo. Crea un usuario normal (ver docs/DEPLOY.md, Parte C)."
  exit 1
fi
[ -f docker-compose.yml ] || { echo "❌ No encuentro docker-compose.yml. Ejecuta el script dentro del proyecto."; exit 1; }
[ -f .env ] || ./scripts/gen_env.sh

env_get() { grep -E "^$1=" .env | head -n1 | cut -d= -f2-; }
PROJECT_NAME="$(env_get COMPOSE_PROJECT_NAME)"
DOMAIN_NAME="$(env_get DOMAIN_NAME)"
BACKEND_PORT="$(env_get BACKEND_PORT)"
FRONTEND_PORT="$(env_get FRONTEND_PORT)"
ADMINER_PORT="$(env_get ADMINER_PORT)"

if [ "$DOMAIN_NAME" = "localhost" ] || [ "$(env_get DJANGO_DEBUG)" != "False" ]; then
  echo "❌ El .env está en modo local (DOMAIN_NAME=localhost o DJANGO_DEBUG=True)."
  echo "   Bórralo y ejecuta ./scripts/gen_env.sh con tu dominio real."
  exit 1
fi

OS_ID="$(. /etc/os-release && echo "${ID:-}")"
OS_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"
case "$OS_ID" in debian|ubuntu) ;; *) echo "❌ Solo Debian/Ubuntu (detectado: ${OS_ID:-desconocido})."; exit 1;; esac

echo "--- Despliegue de '${PROJECT_NAME}' en https://${DOMAIN_NAME} ---"
read -r -p "Correo para el certificado SSL (Let's Encrypt): " EMAIL
[ -n "$EMAIL" ] || { echo "❌ El correo es obligatorio."; exit 1; }

echo "==> [1/8] Comprobando DNS"
SERVER_IP="$(curl -fsS https://api.ipify.org 2>/dev/null || true)"
DNS_IP="$(getent ahostsv4 "$DOMAIN_NAME" 2>/dev/null | awk 'NR==1{print $1}' || true)"
if [ -z "$DNS_IP" ] || { [ -n "$SERVER_IP" ] && [ "$SERVER_IP" != "$DNS_IP" ]; }; then
  echo "⚠️  ${DOMAIN_NAME} resuelve a '${DNS_IP:-nada}' y este servidor es '${SERVER_IP:-desconocido}'."
  echo "    Si el DNS no apunta aquí, Certbot fallará."
  read -r -p "¿Continuar de todos modos? (s/N) " ANS
  [[ "$ANS" =~ ^[Ss]$ ]] || exit 1
fi

echo "==> [2/8] Paquetes base"
sudo apt-get update -y
sudo apt-get install -y curl git ufw ca-certificates

echo "==> [3/8] Docker"
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS_ID} ${OS_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
fi
sudo usermod -aG docker "$USER" || true
DOCKER=(docker)
docker info >/dev/null 2>&1 || DOCKER=(sudo docker)   # el grupo 'docker' aplica en tu próximo login

echo "==> [4/8] Firewall (los contenedores solo escuchan en 127.0.0.1)"
SSH_PORT="$(sudo sshd -T 2>/dev/null | awk '$1=="port"{print $2; exit}' || true)"
sudo ufw allow "${SSH_PORT:-22}/tcp"
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

echo "==> [5/8] Construyendo y levantando contenedores"
"${DOCKER[@]}" compose up -d --build
echo "    Esperando al backend en 127.0.0.1:${BACKEND_PORT}..."
OK=0
for _ in $(seq 1 40); do
  if curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/health/" >/dev/null 2>&1; then OK=1; break; fi
  sleep 3
done
[ "$OK" -eq 1 ] || { echo "❌ El backend no respondió. Revisa: ${DOCKER[*]} compose logs backend"; exit 1; }
echo "    Backend OK."

echo "==> [6/8] Nginx del host"
command -v nginx >/dev/null 2>&1 || { sudo apt-get install -y nginx; sudo systemctl enable --now nginx; }

VHOST_PATH="/etc/nginx/sites-available/${DOMAIN_NAME}.conf"
CONFLICTS="$(sudo grep -rlE "server_name[^;]*${DOMAIN_NAME}" /etc/nginx/conf.d /etc/nginx/sites-enabled 2>/dev/null | grep -v -- "/${DOMAIN_NAME}.conf" || true)"
if [ -n "$CONFLICTS" ]; then
  echo "❌ Ya hay otro vhost con server_name ${DOMAIN_NAME} (causa 502 por bloques duplicados):"
  echo "$CONFLICTS"
  echo "   Bórralos o renómbralos y vuelve a ejecutar."
  exit 1
fi

HTPASSWD="/etc/nginx/.htpasswd_${PROJECT_NAME}"
if [ ! -f "$HTPASSWD" ]; then
  sudo apt-get install -y apache2-utils
  echo "    Crea la clave para /adminer/ (usuario: admin)"
  sudo htpasswd -c "$HTPASSWD" admin
fi

sed \
  -e "s|__DOMAIN__|${DOMAIN_NAME}|g" \
  -e "s|__PROJECT_NAME__|${PROJECT_NAME}|g" \
  -e "s|__BACKEND_PORT__|${BACKEND_PORT}|g" \
  -e "s|__FRONTEND_PORT__|${FRONTEND_PORT}|g" \
  -e "s|__ADMINER_PORT__|${ADMINER_PORT}|g" \
  -e "s|__PROJECT_DIR__|${PROJECT_DIR}|g" \
  nginx-host/vhost.conf.template | sudo tee "$VHOST_PATH" >/dev/null
sudo ln -sf "$VHOST_PATH" "/etc/nginx/sites-enabled/${DOMAIN_NAME}.conf"
sudo nginx -t
sudo systemctl reload nginx

echo "==> [7/8] Certificado HTTPS"
command -v certbot >/dev/null 2>&1 || sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "$DOMAIN_NAME" -m "$EMAIL" --agree-tos --redirect --non-interactive
sudo certbot renew --dry-run

echo "==> [8/8] Listo"
echo "   Crear el primer superusuario:  ${DOCKER[*]} compose exec backend python manage.py createsuperuser"
echo "   Adminer (con clave):           https://${DOMAIN_NAME}/adminer/"
echo "✅ Despliegue completo: https://${DOMAIN_NAME}"
