# Mi Framework

Plantilla full-stack **modular con roles y permisos (RBAC)**: Django REST + Vue 3 + Docker, lista para producción detrás de Nginx + Certbot.

## Stack
- **Backend:** Django 5.2 LTS · DRF · SimpleJWT · PostgreSQL 16 · WhiteNoise
- **Frontend:** Vue 3 (Composition API) · Vite · Pinia · Vue Router · Tailwind 3 · Heroicons
- **Infra:** Docker Compose · Nginx (host) + Certbot · Adminer (protegido con clave)

## Arranque local
```bash
./scripts/gen_env.sh                     # crea .env (si no usaste 01_crear.sh)
docker compose up -d --build             # migra, sincroniza permisos, recolecta estáticos
docker compose exec backend python manage.py createsuperuser
```
Abre `http://localhost:8081` (los puertos salen de tu `.env`). El frontend ya reenvía `/api` y `/admin` al backend, no necesitas Nginx local.

## Agregar un módulo (1 comando)
```bash
./scripts/new-module.sh inventario "Inventario"
```
Detalle en [`docs/MODULES_GUIDE.md`](docs/MODULES_GUIDE.md).

## Documentación (léela en este orden)
| Archivo | Para qué |
|---|---|
| [`docs/PROJECT.md`](docs/PROJECT.md) | Visión, reglas generales y **protocolo para abrir un chat nuevo** |
| [`docs/STATUS.md`](docs/STATUS.md) | Dónde estamos y el próximo paso exacto |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Mapa del sistema y cómo se enganchan los módulos |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | Nombres, permisos, estilo |
| [`docs/BUSINESS_RULES.md`](docs/BUSINESS_RULES.md) | Reglas de negocio con ID (fuente de verdad) |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | Qué se decidió, cuándo y por qué |
| [`docs/MODULES_GUIDE.md`](docs/MODULES_GUIDE.md) | Receta para crear módulos y protegerlos con permisos |
| [`docs/DEPLOY.md`](docs/DEPLOY.md) | Local → GitHub → VPS con dominio |
| [`docs/GITHUB_WORKFLOW.md`](docs/GITHUB_WORKFLOW.md) | Ramas, commits, imágenes en GHCR |
| [`docs/DESIGN.md`](docs/DESIGN.md) | Paleta y tokens de diseño |
| `docs/modules/*.md` | Un archivo por módulo |
