# Guía de despliegue en VPS (Debian/Ubuntu) — Mi Framework

> Objetivo de este documento: que puedas desplegar el proyecto en **cualquier VPS Debian o Ubuntu limpio**, entendiendo el porqué de cada paso, no solo copiando comandos. Está pensada para que sirva tanto si el VPS es exclusivo para este proyecto como si vas a alojar varios proyectos en el mismo servidor.

---

## 0. Antes de empezar (prerrequisitos)

- VPS con **Debian 11/12** o **Ubuntu 22.04/24.04** recién creado.
- Acceso por SSH (usuario root o con sudo).
- Un **dominio** cuyo registro DNS tipo `A` ya apunte a la IP pública del VPS. Esto es obligatorio para el paso de SSL — Certbot valida que el dominio resuelva a ese servidor antes de emitir el certificado.
- Los puertos 22, 80 y 443 abiertos en el firewall del proveedor de VPS (esto es distinto del firewall del sistema operativo, que configuramos en el paso 2).

**Por qué importa el orden**: cada paso de esta guía depende de que el anterior haya funcionado. Si saltas pasos (por ejemplo, pides el certificado SSL antes de que el DNS propague), vas a perder tiempo debugueando síntomas en el paso equivocado.

---

## 1. Crear un usuario no-root y asegurar el acceso SSH

```bash
adduser deploy
usermod -aG sudo deploy
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy
```

Luego, en `/etc/ssh/sshd_config`, cambia:
```
PermitRootLogin no
PasswordAuthentication no
```
y reinicia SSH: `sudo systemctl restart sshd`.

**Por qué**: operar como root todo el tiempo es la forma más común de convertir un error tonto (`rm -rf` en el directorio equivocado) en un desastre irreversible. Un usuario con sudo te obliga a confirmar acciones destructivas y limita el daño de una clave SSH comprometida.

---

## 2. Firewall del sistema operativo (ufw)

```bash
sudo apt update -y
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

**Por qué**: por defecto Docker publica los puertos de los contenedores solo en `127.0.0.1` (ya lo hace bien tu `docker-compose.yml`), así que técnicamente no necesitas abrir más puertos. Pero un firewall explícito es tu segunda capa de defensa: si algún día alguien cambia por error un `127.0.0.1:8000:8000` por `8000:8000` en el compose, el firewall sigue bloqueando el acceso externo a ese puerto.

---

## 3. Instalar Docker Engine y el plugin de Compose (versión corregida)

Tu `deploy.sh` actual tiene un bug real aquí: **hardcodea el repositorio de Docker para Debian** aunque el sistema sea Ubuntu. Docker publica repos APT separados para cada distro (`linux/debian` y `linux/ubuntu`), con codenames distintos. Si tu VPS es Ubuntu y el script asume Debian, la instalación puede fallar o instalar la versión incorrecta.

Versión corregida (detecta la distro real):

```bash
. /etc/os-release
DISTRO_ID="$ID"   # "debian" o "ubuntu"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DISTRO_ID} $VERSION_CODENAME stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
```

**Por qué**: la línea `$ID` viene de `/etc/os-release` y es el identificador oficial de la distro (`debian`, `ubuntu`, etc.) — usarlo en vez de asumir uno fijo es lo que hace que el script funcione en ambas familias sin cambiar una sola línea. El `usermod -aG docker` evita que tengas que anteponer `sudo` a cada comando de Docker (y evita correr todo como root innecesariamente).

---

## 4. Clonar el repositorio y configurar variables de entorno

```bash
git clone <url-de-tu-repo> framework
cd framework
cp .env.example .env    # si no existe .env.example en el repo, créalo ahora (ver nota abajo)
nano .env
```

Variables mínimas que tu `docker-compose.yml` y `deploy.sh` ya esperan:

| Variable | Para qué sirve |
|---|---|
| `DOMAIN_NAME` | Dominio público, usado por Nginx y Certbot |
| `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | Credenciales de la base de datos |
| `BACKEND_PORT`, `FRONTEND_PORT`, `ADMINER_PORT` | Puertos internos publicados solo en `127.0.0.1` |
| `COMPOSE_PROJECT_NAME` | Prefijo de nombres de contenedores (útil si compartes el VPS) |

**Nota importante**: el README menciona `.env.example` pero al revisar el repo no aparece listado junto a los demás archivos. Antes de seguir, confirma que existe — si no, créalo con las variables de arriba para que cualquier persona (o IA) pueda replicar el entorno sin adivinar qué variables hacen falta.

**Por qué esto importa especialmente si el VPS es compartido**: si terminas alojando más de un proyecto en el mismo servidor, `COMPOSE_PROJECT_NAME` y los puertos deben ser únicos por proyecto para que Docker no intente reusar nombres de contenedor o puertos ya ocupados.

---

## 5. Levantar los contenedores

```bash
docker compose up -d --build
```

**Por qué construir en el VPS (la opción que elegiste)**: es más simple de operar — no necesitas un registry de imágenes ni un pipeline de CI. La contrapartida es que el build consume CPU/RAM del propio servidor de producción durante unos minutos, y no tienes un artefacto versionado de "qué imagen exacta corre en producción" (si algo sale mal, tienes que reconstruir con el mismo commit para reproducir el problema). Es una decisión razonable para un VPS pequeño-mediano; si el proyecto crece o el build empieza a tardar/consumir demasiado, ese es el momento de mover el build a GitHub Actions + GHCR (lo dejo documentado como módulo pendiente en `03-CONTEXTO-MODULO-INFRA.md`).

---

## 6. Migraciones, estáticos y verificación de arranque

Esto **falta hoy en tu flujo de despliegue** y es importante no saltarlo:

```bash
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py collectstatic --noinput
```

Luego verifica que el backend responde antes de seguir:

```bash
for i in $(seq 1 30); do
  curl -sf "http://127.0.0.1:${BACKEND_PORT}/api/health/" && break
  sleep 2
done
```

**Por qué**: levantar los contenedores "sanos" no significa que la aplicación esté lista — sin `migrate` la base de datos está vacía (el primer login fallará), y sin `collectstatic` Django no tiene los archivos estáticos que Nginx necesita servir. Verificar el healthcheck antes de tocar Nginx/SSL evita que expongas al público una app a medio arrancar.

---

## 7. Configurar el Nginx del host (reverse proxy)

```bash
sudo apt install -y nginx
VHOST_PATH="/etc/nginx/sites-available/${DOMAIN_NAME}.conf"
sudo sed \
  -e "s/__DOMAIN__/${DOMAIN_NAME}/g" \
  -e "s/__BACKEND_PORT__/${BACKEND_PORT}/g" \
  -e "s/__FRONTEND_PORT__/${FRONTEND_PORT}/g" \
  -e "s|__PROJECT_DIR__|$(pwd)|g" \
  nginx-host/vhost.conf.template | sudo tee "$VHOST_PATH" > /dev/null
sudo ln -sf "$VHOST_PATH" "/etc/nginx/sites-enabled/${DOMAIN_NAME}.conf"
sudo nginx -t
sudo systemctl reload nginx
```

**Por qué Nginx en el host y no en un contenedor**: si el VPS termina siendo compartido con otros proyectos, un único Nginx en el host puede enrutar por dominio/subdominio hacia cada `docker-compose` sin conflictos de puerto 80/443 (solo puede haber un proceso escuchando esos puertos en el host). Si más adelante confirmas que el VPS es **exclusivo** para este proyecto, puedes migrar a Nginx+Certbot dentro de Docker (ver Apéndice A) — pero la versión de host es la que funciona en ambos escenarios sin cambios, así que es el default correcto mientras no sepas cuál será tu caso.

### Proteger Adminer

Adminer es una herramienta de administración de base de datos — no debería quedar accesible sin fricción en producción. Añade autenticación básica en el bloque de Nginx que apunta a Adminer:

```bash
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd_adminer admin
```

Y en el `location` de Adminer dentro de tu vhost:
```nginx
location /adminer/ {
    auth_basic "Restringido";
    auth_basic_user_file /etc/nginx/.htpasswd_adminer;
    proxy_pass http://127.0.0.1:__ADMINER_PORT__/;
}
```

**Por qué**: aunque el puerto ya está limitado a `127.0.0.1`, en cuanto lo expones a través de Nginx para poder usarlo tú mismo, también queda expuesto a cualquiera que adivine la URL. Una capa de autenticación básica es el mínimo razonable.

---

## 8. Certificado SSL con Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d "${DOMAIN_NAME}" -m "tu-email@dominio.com" --agree-tos --redirect --non-interactive
sudo certbot renew --dry-run
```

**Por qué**: `--redirect` fuerza que todo el tráfico HTTP se redirija a HTTPS automáticamente (evita que alguien navegue sin cifrar por error). El `--dry-run` simula la renovación automática sin gastar tu cuota de emisión — Certbot instala un timer systemd que renueva el certificado antes de que expire, pero vale la pena confirmar que funciona ahora, no cuando falte un día para que expire.

---

## 9. Crear superusuario de Django

```bash
docker compose exec backend python manage.py createsuperuser
```

---

## 10. Checklist de verificación final

- [ ] `https://tu-dominio.com` carga el frontend
- [ ] `https://tu-dominio.com/api/` responde (backend)
- [ ] El panel admin de Django funciona con el superusuario creado
- [ ] Adminer pide usuario/contraseña antes de mostrar nada
- [ ] `http://tu-dominio.com` (sin S) redirige automáticamente a HTTPS
- [ ] `sudo certbot renew --dry-run` no da error

---

## 11. Lo que falta construir (pendientes reales, no cosméticos)

Estos puntos **no están resueltos hoy** en el repo y te recomiendo tratarlos como módulos de infraestructura a construir (ver `03-CONTEXTO-MODULO-INFRA.md`):

1. **Healthcheck de Postgres** en `docker-compose.yml` + `depends_on: condition: service_healthy` en `backend`, para que el backend no arranque antes de que la base de datos esté realmente lista.
2. **Script de re-despliegue** (`update.sh`): `git pull` + rebuild + `migrate` + `collectstatic` + restart, para no repetir manualmente el proceso completo en cada actualización.
3. **Backup automático de Postgres**: `pg_dump` vía cron con rotación de respaldos antiguos.
4. **Rotación de logs de Docker**: configurar `logging.driver: json-file` con `max-size`/`max-file` en el compose, para que los logs de los contenedores no llenen el disco con el tiempo.
5. (Opcional, a futuro) **Pipeline CI/CD**: build + push de imágenes a GHCR, para dejar de construir en el propio VPS cuando el proyecto crezca.

---

## Apéndice A: Si confirmas que el VPS es exclusivo para este proyecto

En ese caso puedes dockerizar Nginx + Certbot en vez de usar el Nginx del host (contenedores `nginx:alpine` + `certbot/certbot`), lo que hace que el `docker-compose.yml` sea 100% autocontenido y portable a cualquier VPS sin instalar nada fuera de Docker. Es más trabajo inicial (manejo de volúmenes compartidos para los certificados, renovación vía contenedor en vez de systemd timer), así que solo vale la pena si tienes la certeza de que no vas a compartir el servidor. Si llegas a ese punto, dímelo y armamos esa variante.
