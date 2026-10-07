#!/usr/bin/env bash
###############################################################################
# scripts/clean.sh — Borra SOLO este proyecto (contenedores, volúmenes, vhost y,
# opcionalmente, la carpeta). No toca otros proyectos Docker de la máquina.
###############################################################################
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
PROJECT_DIR="$(pwd)"

[ -f docker-compose.yml ] && [ -f .env ] || { echo "❌ Ejecútalo dentro de un proyecto (falta docker-compose.yml o .env)."; exit 1; }
env_get() { grep -E "^$1=" .env | head -n1 | cut -d= -f2-; }
PROJECT_NAME="$(env_get COMPOSE_PROJECT_NAME)"
DOMAIN_NAME="$(env_get DOMAIN_NAME)"
[ -n "$PROJECT_NAME" ] || { echo "❌ COMPOSE_PROJECT_NAME vacío en .env."; exit 1; }

echo "⚠️  Se eliminarán contenedores, redes y VOLÚMENES (¡incluida la base de datos!) del proyecto '${PROJECT_NAME}'."
read -r -p "Escribe el nombre del proyecto para confirmar: " CONFIRM
[ "$CONFIRM" = "$PROJECT_NAME" ] || { echo "❌ Cancelado."; exit 1; }

echo "==> [1/3] Contenedores, redes y volúmenes del proyecto"
docker compose down --volumes --remove-orphans

echo "==> [2/3] Nginx del host (opcional)"
read -r -p "¿Borrar también el vhost y la clave de Adminer de ${DOMAIN_NAME}? (s/N) " ANS
if [[ "$ANS" =~ ^[Ss]$ ]]; then
  sudo rm -f "/etc/nginx/sites-enabled/${DOMAIN_NAME}.conf" "/etc/nginx/sites-available/${DOMAIN_NAME}.conf" "/etc/nginx/.htpasswd_${PROJECT_NAME}"
  sudo nginx -t && sudo systemctl reload nginx
fi

echo "==> [3/3] Carpeta del proyecto (opcional)"
read -r -p "¿Borrar la carpeta ${PROJECT_DIR}? Escribe el nombre del proyecto otra vez, o Enter para conservarla: " CONFIRM2
if [ "$CONFIRM2" = "$PROJECT_NAME" ] && [ "$PROJECT_DIR" != "/" ] && [ "$PROJECT_DIR" != "$HOME" ]; then
  cd ..
  rm -rf -- "$PROJECT_DIR"
  echo "✅ Carpeta eliminada."
else
  echo "Carpeta conservada."
fi
echo "✅ Limpieza terminada."
