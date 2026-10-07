# GITHUB_WORKFLOW

## 1. Primera subida
```bash
cd <proyecto>
git status                      # verifica que .env NO aparece
git add .
git commit -m "chore: scaffold inicial del proyecto"
```
En GitHub crea un repo **vacío** (sin README ni .gitignore; ya los tienes). Luego:
```bash
git remote add origin https://github.com/<usuario>/<repo>.git
git branch -M main
git push -u origin main
```
- `.env` está en `.gitignore`; `.env.example` sí se sube (solo placeholders).
- También se ignoran `*.sql`, `backups/`, `node_modules/`, `dist/` y los estáticos generados.
- Si git no te deja por autenticación, usa un *Personal Access Token* (HTTPS) o una llave SSH.

## 2. Ramas
- `main`: siempre desplegable.
- `develop`: integración.
- `feature/<nombre>` / `fix/<nombre>`: una por tarea → PR a `develop` → PR a `main` → tag `vX.Y.Z`.

## 3. Commits
`tipo: descripción corta` — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`. Ej.: `feat: permisos del módulo inventario`.
Commitea **junto con el código**: migraciones, `docs/modules/<m>.md`, `STATUS.md`.

## 4. Clonar en otro equipo o en el VPS
```bash
git clone https://github.com/<usuario>/<repo>.git <proyecto>
cd <proyecto>
./scripts/gen_env.sh          # crea el .env con secretos nuevos
```

## 5. Imágenes en GitHub Container Registry (Fase 4, pendiente)
Hoy el VPS construye las imágenes desde el código. Para publicarlas en GHCR:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u <usuario> --password-stdin   # token con write:packages
docker build -t ghcr.io/<usuario>/<repo>-backend:v1.0 ./backend && docker push ghcr.io/<usuario>/<repo>-backend:v1.0
docker build -t ghcr.io/<usuario>/<repo>-frontend:v1.0 ./frontend && docker push ghcr.io/<usuario>/<repo>-frontend:v1.0
```
⚠️ El `docker-compose.yml` actual monta `./backend:/app` (pensado para desarrollo y VPS con código). Para producción solo con imágenes, la Fase 4 crea un `docker-compose.prod.yml` con `image:` y **sin** ese volumen. Después se automatiza con GitHub Actions al hacer `git tag v*`.
