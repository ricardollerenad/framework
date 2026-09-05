#!/usr/bin/env bash
###############################################################################
# clean-all.sh
#
# Automatiza el borrado completo de contenedores, redes, volúmenes de Docker
# y carpetas de proyectos anteriores para una instalación totalmente limpia.
###############################################################################
set -euo pipefail

echo "⚠️  ATENCIÓN: Este script eliminará contenedores, redes, volúmenes (incluyendo bases de datos) y carpetas de proyectos."
read -p "¿Estás seguro de que deseas continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

echo "==> [1/4] Deteniendo y eliminando contenedores y redes del proyecto actual (si estás dentro de la carpeta)..."
if [ -f "docker-compose.yml" ]; then
  docker compose down --volumes --remove-orphans || true
fi

echo "==> [2/4] Realizando limpieza general de Docker (contenedores detenidos, redes huérfanas y volúmenes sin uso)..."
docker container prune -f
docker volume prune -f
docker network prune -f

echo "==> [3/4] Eliminando carpetas de proyectos anteriores..."
read -p "Introduce el nombre de la carpeta del proyecto que deseas borrar (o déjalo en blanco para omitir): " TARGET_DIR

if [ -n "$TARGET_DIR" ] && [ -d "$TARGET_DIR" ]; then
  rm -rf "$TARGET_DIR"
  echo "✅ Carpeta '$TARGET_DIR' eliminada correctamente."
elif [ -n "$TARGET_DIR" ]; then
  echo "⚠️ La carpeta '$TARGET_DIR' no existe en la ruta actual."
fi

echo "==> [4/4] Limpieza finalizada con éxito."
echo "Tu entorno está limpio y listo para ejecutar nuevamente el script 01-scaffold.sh."