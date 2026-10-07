#!/usr/bin/env bash
###############################################################################
# 01_crear.sh — Crea un proyecto nuevo a partir de ./template
# Uso:  ./01_crear.sh        (SIN sudo: los archivos deben quedar a tu nombre)
###############################################################################
set -euo pipefail
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${KIT_DIR}/template"

if [ -n "${SUDO_UID:-}" ] || [ "$(id -u)" -eq 0 ]; then
  echo "❌ No uses sudo ni root: los archivos quedarían con dueño root. Ejecuta: ./01_crear.sh"
  exit 1
fi
[ -d "$TEMPLATE_DIR" ] || { echo "❌ No encuentro ${TEMPLATE_DIR}"; exit 1; }

echo "--- Nuevo proyecto ---"
read -r -p "Nombre de la carpeta (minúsculas, sin espacios; ej: sistema_1): " PROJECT_NAME
[[ "$PROJECT_NAME" =~ ^[a-z][a-z0-9_]*$ ]] || { echo "❌ Usa minúsculas, números y _ (empieza con letra)."; exit 1; }

DEST="$(pwd)/${PROJECT_NAME}"
[ ! -e "$DEST" ] || { echo "❌ '${DEST}' ya existe. Elige otro nombre o bórralo."; exit 1; }

cp -r "$TEMPLATE_DIR" "$DEST"
chmod +x "$DEST"/scripts/*.sh
cd "$DEST"

# Crea el .env (pregunta dominio y puertos; genera los secretos)
./scripts/gen_env.sh

if command -v git >/dev/null 2>&1; then
  git init -q -b main 2>/dev/null || git init -q
  echo "✅ Repositorio Git inicializado (aún sin commits)."
fi

echo ""
echo "✅ Proyecto creado en ${DEST}"
echo "   Siguiente:  cd ${PROJECT_NAME} && docker compose up -d --build"
echo "   Luego:      docker compose exec backend python manage.py createsuperuser"
echo "   Guía:       docs/PROJECT.md  y  docs/DEPLOY.md"
