#!/usr/bin/env bash
###############################################################################
# 02-deploy.sh (Versión Completa e Interactiva)
###############################################################################
set -euo pipefail

if [ ! -f "docker-compose.yml" ] || [ ! -f ".env" ]; then
  echo "❌ Ejecuta este script DENTRO de la carpeta del proyecto (falta docker-compose.yml o .env)."
  exit 1
fi

PROJECT_DIR="$(pwd)"
source .env

echo "--- Despliegue Automatizado ---"
echo "Dominio detectado en el archivo .env: $DOMAIN_NAME"
read -p "Introduce tu correo electrónico para el certificado SSL (Certbot): " EMAIL

if [ -z "$EMAIL" ]; then
  echo "❌ El correo electrónico es obligatorio para generar el certificado SSL."
  exit 1
fi

echo "==> [1/7] Paquetes base"
sudo apt update -y
sudo apt install -y curl git ufw

echo "==> [2/7] Docker"
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update -y
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
else
  echo "Docker ya esta instalado, se omite."
fi

echo "==> [3/7] Firewall (NO se abre el puerto de los contenedores: solo escuchan en 127.0.0.1)"
sudo ufw allow 22/tcp || true
sudo ufw allow 80/tcp || true
sudo ufw allow 443/tcp || true
sudo ufw --force enable || true

echo "==> [4/7] Construyendo y levantando contenedores"
docker compose up -d --build

echo "    Esperando a que el backend responda en 127.0.0.1:${BACKEND_PORT}..."
for i in $(seq 1 30); do
  if curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/health/" >/dev/null 2>&1; then
    echo "    Backend OK."
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "⚠️  El backend no respondio a tiempo. Revisa: docker compose logs backend"
  fi
done

echo "==> [5/7] Generando vhost para el Nginx del host"
if ! command -v nginx >/dev/null 2>&1; then
  echo "    Nginx no detectado. Instalando..."
  sudo apt install -y nginx
  sudo systemctl enable --now nginx
fi

VHOST_PATH="/etc/nginx/sites-available/${DOMAIN_NAME}.conf"
sudo bash -c "sed \
  -e 's/__DOMAIN__/${DOMAIN_NAME}/g' \
  -e 's/__BACKEND_PORT__/${BACKEND_PORT}/g' \
  -e 's/__FRONTEND_PORT__/${FRONTEND_PORT}/g' \
  -e 's/__ADMINER_PORT__/${ADMINER_PORT}/g' \
  -e 's|__PROJECT_DIR__|${PROJECT_DIR}|g' \
  '${PROJECT_DIR}/nginx-host/vhost.conf.template' > '${VHOST_PATH}'"

sudo ln -sf "${VHOST_PATH}" "/etc/nginx/sites-enabled/${DOMAIN_NAME}.conf"
sudo nginx -t
sudo systemctl reload nginx

echo "==> [6/7] Certificado SSL con el Certbot del host"
if ! command -v certbot >/dev/null 2>&1; then
  sudo apt install -y certbot python3-certbot-nginx
fi
sudo certbot --nginx -d "${DOMAIN_NAME}" -m "${EMAIL}" --agree-tos --redirect --non-interactive

echo "==> [7/7] Listo. Operaciones post-despliegue"
echo ""
echo "Crear superusuario de Django:"
echo "  docker compose exec backend python manage.py createsuperuser"
echo ""
echo "Probar renovacion automatica del certificado:"
echo "  sudo certbot renew --dry-run"
echo ""
echo "✅ Despliegue completo. Tu sitio deberia responder en https://${DOMAIN_NAME}"
