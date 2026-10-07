# DEPLOY — local → GitHub → VPS con dominio

Reemplaza a `secuencia.md`. Los comandos de otros proyectos (p. ej. Moodle) ya no van aquí: cada proyecto tiene su propio `docs/DEPLOY.md`.

## Parte A — Local
**Requisitos:** Git, Docker con el plugin Compose, tu usuario en el grupo `docker` (`sudo usermod -aG docker $USER` y vuelve a entrar).
```bash
cd ~/kit && ./01_crear.sh                # SIN sudo. Pide nombre, dominio ('localhost'), puertos
cd <proyecto>
docker compose up -d --build
docker compose ps                        # db healthy, backend/frontend/adminer Up
docker compose logs -f --tail=30 backend # debe mostrar migraciones, "Permisos: 8 activos…" y gunicorn
docker compose exec backend python manage.py createsuperuser
```
**Verificación (resultado esperado):**
| Comando | Esperado |
|---|---|
| `curl -s http://127.0.0.1:8001/api/health/` | `{"status":"ok"}` |
| `curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/` | `200` |
| Abrir `http://localhost:8081` | Pantalla de login |
| Entrar con el superusuario → menú **Seguridad** | Roles y Usuarios y roles visibles |
| Probar `http://localhost:8081/admin/` | Panel de Django |

(Si cambiaste puertos, usa los de tu `.env`.) Con Nginx propio en tu PC: apunta un vhost a `127.0.0.1:<FRONTEND_PORT>` (con `proxy_pass` a `/`); el contenedor ya reenvía `/api`.

**Día a día**
```bash
docker compose exec backend python manage.py makemigrations <modulo>
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py test
docker compose restart backend                       # tras cambiar código Python o agregar módulo
docker compose up -d --build frontend                # tras cambiar el frontend
docker compose logs -f --tail=30 <backend|frontend|db>
./scripts/backup_db.sh                               # guarda en ./backups (ignorado por Git)
```

## Parte B — GitHub
Sigue `docs/GITHUB_WORKFLOW.md` (sección 1). Antes del primer push comprueba con `git status` que no aparece `.env`.

## Parte C — VPS con dominio
**1. DNS:** crea un registro **A** `tu.dominio.com → IP del VPS` y espera a que resuelva (`getent hosts tu.dominio.com`).

**2. Primer ingreso (como root) — crea un usuario normal:**
```bash
adduser deploy && usermod -aG sudo deploy
# Copia tu llave SSH: ssh-copy-id deploy@IP   (desde tu PC)
# Prueba entrar como deploy en otra terminal ANTES de cerrar la de root
```
Opcional pero recomendable: en `/etc/ssh/sshd_config` pon `PermitRootLogin no` y `PasswordAuthentication no`, luego `systemctl reload ssh`.

**3. Como `deploy`:**
```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/<usuario>/<repo>.git ~/<proyecto> && cd ~/<proyecto>
./scripts/gen_env.sh        # dominio REAL (no localhost). Genera secretos nuevos
./scripts/02_deploy.sh      # Docker, firewall, contenedores, Nginx, clave de Adminer, HTTPS
```
El script: comprueba DNS, instala Docker, abre solo 22/80/443, levanta los contenedores (el backend migra y sincroniza permisos solo), crea el vhost, aborta si hay otro `server_name` igual y pide el certificado.

**4. Después:**
```bash
docker compose exec backend python manage.py createsuperuser   # (usa sudo si aún no reiniciaste sesión)
```
Verifica: `https://tu.dominio.com` (login), `/admin/`, `/adminer/` (pide clave), `sudo certbot renew --dry-run`.

**5. Actualizar después de un cambio:**
```bash
cd ~/<proyecto> && git pull
docker compose up -d --build            # reconstruye lo que cambió; el backend migra al arrancar
docker compose logs --tail=30 backend
```
**Rollback rápido:** `git checkout <commit_anterior> && docker compose up -d --build` (las migraciones ya aplicadas no se revierten solas: haz `./scripts/backup_db.sh` antes de actualizar).

## Errores frecuentes
| Síntoma | Causa probable | Solución |
|---|---|---|
| 502 Bad Gateway | Vhost duplicado o backend caído | `sudo nginx -t`, `grep -r server_name /etc/nginx/`, `docker compose ps` |
| Login del admin da 403 CSRF | `CSRF_TRUSTED_ORIGINS` no coincide con el dominio/https | Corrige `.env` y `docker compose up -d --force-recreate backend` |
| Puerto ocupado al levantar | Otro proyecto usa ese puerto | `sudo ss -tlnp \| grep <puerto>` y cambia el puerto en `.env` |
| Archivos de root en el proyecto | Se ejecutó algo con `sudo` | `sudo chown -R $USER:$USER .` y no uses sudo en los scripts |
| F5 en una ruta da 404 | Falta `try_files` del frontend | Ya incluido en `frontend/nginx.conf`; reconstruye `frontend` |
