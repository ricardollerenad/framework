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

```bash
git clone <url-del-repo>
cd framework
cp .env.example .env   # completa tus variables
docker compose up -d --build
```

- Frontend: http://localhost:8081
- Backend API: http://localhost:8001/api/
- Adminer (DB): http://localhost:8082

## 🌐 Desplegar en un servidor nuevo

Ver [`docs/GITHUB_WORKFLOW.md`](./docs/GITHUB_WORKFLOW.md) para el flujo completo de build + push de imágenes a GitHub Container Registry, y `02-deploy.sh` para el despliegue automatizado con Nginx + SSL.

## 🗺️ Estado del proyecto

Ver [`docs/ROADMAP.md`](./docs/ROADMAP.md) para las fases completadas y pendientes.

## 🏗️ Convenciones de arquitectura

Ver [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) antes de agregar cualquier módulo nuevo — ahí están las reglas de dónde va cada cosa.
