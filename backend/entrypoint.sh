#!/bin/sh
set -e

echo "Esperando a la base de datos PostgreSQL..."
while ! nc -z db 5432; do
  sleep 0.5
done
echo "PostgreSQL listo."

echo "Ejecutando migraciones de Django..."
python manage.py migrate --noinput

echo "Recolectando archivos estaticos..."
python manage.py collectstatic --noinput

exec "$@"
