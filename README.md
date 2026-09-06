# Mi Framework

Plantilla base full-stack para desplegar rápidamente proyectos con **Django REST Framework** (backend) + **Vue 3 + Vite + TypeScript + Tailwind** (frontend), contenedorizados con Docker y listos para producción detrás de Nginx + Certbot.

## 📦 Stack

- **Backend:** Django 4.2 + Django REST Framework + SimpleJWT + PostgreSQL
- **Frontend:** Vue 3 (Composition API) + Vite + TypeScript + Pinia + Vue Router + Tailwind CSS + Heroicons
- **Infra:** Docker Compose, Nginx (host, como reverse proxy) + Certbot (SSL), Adminer (gestión DB)

## 📁 Estructura del proyecto

```
framework/
├── backend/                 # Django REST API
│   ├── core/                 # Configuración global (settings, urls, wsgi)
│   ├── apps/                  # Cada módulo de negocio vive aquí (ver ARCHITECTURE.md)
│   │   └── authentication/    # Login JWT, sesiones, trazabilidad de usuario
│   └── common/                 # Utilidades compartidas entre apps
├── frontend/
│   └── src/
│       ├── modules/            # Cada feature vive en su propia carpeta (ver ARCHITECTURE.md)
│       │   └── auth/
│       ├── shared/              # Componentes, composables, iconos reutilizables
│       ├── layouts/              # LayoutMain (sidebar + topbar estilo Odoo)
│       ├── router/
│       └── stores/
├── nginx-host/                # Plantilla de vhost para el Nginx del servidor
├── docs/                       # Toda la documentación del proyecto (estás aquí)
├── docker-compose.yml
└── .env
```

## 🚀 Levantar en local
---
#Pasos para recrearlo

## Paso 1. Subir los archivos a GitHub desde esta PC
```bash
git clone https://github.com/ricardollerenad/framework
cd framework
nano .env
cp .env.example .env    # si no existe .env.example en el repo, créalo ahora (ver nota abajo)
```  


## Paso 2 — levanta el proyecto (dentro de esa carpeta):
```bash
cd /home/ricardo/framework/sistema_1
docker compose up -d --build
sudo docker compose ps
sudo docker compose exec backend python manage.py makemigrations authentication
sudo docker compose exec backend python manage.py migrate
sudo docker compose exec backend python manage.py collectstatic --noinput
```  

## Paso 3 — crea el vhost de Nginx para este dominio específico:

Creamos el archivo 
```bash
sudo nano /etc/nginx/conf.d/sistema.enarequipa.org.conf
```  
Configuracion de NGINX

```NGINX
server {
    listen 80;
    server_name <<dominio>>

    client_max_body_size 20M;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /home/ricardo/framework/sistema_1/backend/staticfiles/;
    }

    location /media/ {
        alias /home/ricardo/framework/sistema_1/backend/media/;
    }

    location /adminer/ {
        auth_basic "Restringido";
        auth_basic_user_file /etc/nginx/.htpasswd_sistema_1;
        proxy_pass http://127.0.0.1:8082/;
        proxy_set_header Host $host;
    }
}
```  

## Paso 4 — habilítalo y protege Adminer:
```bash
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd_sistema_1 admin
sudo nginx -t
sudo systemctl restart nginx
```  

## Paso 5 — certificado SSL:
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d sistema.enarequipa.org -m tu-correo@dominio.com --agree-tos --redirect --non-interactive
sudo certbot renew --dry-run
sudo systemctl restart nginx
```  

## Comando general

Para recargar modulos o demas:
```bash
#Recarga contenedor Backend
docker compose up -d --force-recreate backend

#Recarga Frontend
docker compose up -d --build frontend

#Prepara las migraciones
sudo docker compose exec backend python manage.py makemigrations

#Realiza las migraciones
sudo docker compose exec backend python manage.py migrate

#Comprueba funcionamiento
sudo docker compose exec backend python manage.py collectstatic --noinput
```  
--- 
- Frontend: http://localhost:8081
- Backend API: http://localhost:8001/api/
- Adminer (DB): http://localhost:8082

## 🌐 Desplegar en un servidor nuevo

Ver [`docs/GITHUB_WORKFLOW.md`](./docs/GITHUB_WORKFLOW.md) para el flujo completo de build + push de imágenes a GitHub Container Registry, y `02-deploy.sh` para el despliegue automatizado con Nginx + SSL.

## 🗺️ Estado del proyecto

Ver [`docs/ROADMAP.md`](./docs/ROADMAP.md) para las fases completadas y pendientes.

## 🏗️ Convenciones de arquitectura

Ver [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) antes de agregar cualquier módulo nuevo — ahí están las reglas de dónde va cada cosa.
