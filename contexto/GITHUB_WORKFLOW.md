# 🐙 Flujo de trabajo con GitHub

## 1. Subir el proyecto por primera vez

```bash
cd framework
git init
git add .
git commit -m "chore: scaffold inicial del proyecto"
```

En GitHub: crea un repo nuevo (privado si el proyecto es propietario) **sin** README/gitignore (ya los tenemos).

```bash
git remote add origin https://github.com/<tu-usuario>/<tu-repo>.git
git branch -M main
git push -u origin main
```

⚠️ Verifica que `.env` esté en `.gitignore` (ya lo está por el scaffold) — **nunca** subas contraseñas de DB ni `DJANGO_SECRET_KEY` al repo.

## 2. Estrategia de ramas (simple, recomendada para este tamaño de proyecto)

- `main` → siempre desplegable, código estable
- `develop` → integración de features antes de pasar a main
- `feature/<nombre>` → una rama por feature (ej. `feature/jwt-auth`, `feature/sidebar-menu`)

Flujo: `feature/x` → PR a `develop` → cuando `develop` está estable → PR a `main` → se genera un tag de versión.

## 3. Imágenes Docker en GitHub Container Registry (GHCR)

GHCR es gratis para repos públicos y privados asociados a tu cuenta, y no necesitas otra cuenta (usa tu login de GitHub).

### Build y push manual (mientras no hay CI configurado)

```bash
# Autenticarte una vez (usa un Personal Access Token con permiso `write:packages`)
echo $GITHUB_TOKEN | docker login ghcr.io -u <tu-usuario> --password-stdin

# Backend
docker build -t ghcr.io/<tu-usuario>/framework-backend:v1.0 ./backend
docker push ghcr.io/<tu-usuario>/framework-backend:v1.0

# Frontend
docker build -t ghcr.io/<tu-usuario>/framework-frontend:v1.0 ./frontend
docker push ghcr.io/<tu-usuario>/framework-frontend:v1.0
```

### Build y push automático (GitHub Actions) — Fase 4 del roadmap

Cuando lleguemos a la Fase 4, crearemos `.github/workflows/build-push.yml` para que cada `git tag v*` dispare el build+push automáticamente. Por ahora, build manual es suficiente mientras iteramos rápido.

## 4. Desplegar en un servidor nuevo usando las imágenes publicadas

En vez de `build: ./backend` en el `docker-compose.yml`, en producción se usa `docker-compose.prod.yml` con:
```yaml
services:
  backend:
    image: ghcr.io/<tu-usuario>/framework-backend:v1.0
  frontend:
    image: ghcr.io/<tu-usuario>/framework-frontend:v1.0
```
Y en el servidor nuevo:
```bash
docker login ghcr.io -u <tu-usuario> --password-stdin
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```
Esto es mucho más rápido que reconstruir desde el código fuente en cada servidor. Este archivo se creará en la Fase 4.

## 5. Convención de commits (recomendada)

`tipo: descripción corta`, tipos comunes: `feat`, `fix`, `chore`, `docs`, `refactor`. Ej: `feat: agregar login JWT con refresh token`.