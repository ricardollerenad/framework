# DECISIONS

Una entrada por decisión: fecha · decisión · motivo · consecuencia. Lo nuevo va arriba.

## 2026-10-06 — Reescritura de la plantilla (v2: modular + roles)
| Decisión | Motivo | Consecuencia / deuda |
|---|---|---|
| RBAC propio (`AccessPermission`, `Role`, `UserRole`) sobre el `User` por defecto de Django | Evitar un `AUTH_USER_MODEL` custom que luego es muy difícil de cambiar; roles editables en UI sin migraciones | El usuario sigue siendo el de Django; la tabla de usuarios no tiene campos extra |
| Permisos declarados en código + `sync_permissions` en cada arranque | El código es la fuente de verdad del catálogo; los roles son datos | Quitar un permiso = deprecarlo (inactivo), nunca borrar |
| Registro único de módulos: `core/modules.py` (back) y `manifest.js` auto-descubierto (front) | Pasar de 2 enganches manuales a 1 línea (back) y 0 ediciones (front) | `new-module.sh` automatiza la línea del backend |
| `sid` como claim del JWT en vez de usar el `jti` | El `jti` del access token cambia en cada refresh: la sesión dejaba de actualizarse y el logout no la cerraba | Sesiones fiables de punta a punta |
| Variables `POSTGRES_*` separadas, sin `DATABASE_URL` | Una contraseña con `@ : / #` rompía la URL | `dj-database-url` ya no se usa |
| Contraseña de BD y SECRET_KEY generadas por `gen_env.sh` | Evitar contraseñas débiles o con caracteres problemáticos | El `.env` nunca se escribe a mano |
| `./backend:/app` como volumen y `user: APP_UID:APP_GID` | Las migraciones creadas en el contenedor se perdían; evitar archivos de root | Si cambias de usuario/máquina, regenera el `.env` |
| WhiteNoise para estáticos de Django | No dar permisos sobre `/home/<user>` a Nginx para servir `/static/` | `/media/` aún requiere permiso de lectura para Nginx |
| Nginx del contenedor frontend con `try_files` y proxy de `/api` | F5 en rutas de la SPA daba 404; el modo local no tenía proxy | Local funciona solo con `localhost:<FRONTEND_PORT>` |
| `COMPOSE_PROJECT_NAME` en `.env` | Sin él, todos los proyectos se llamaban `framework_*` y chocaban | Varios proyectos conviven en una máquina |
| Django 5.2 LTS, Python 3.12, Node 22, PostgreSQL 16 | Django 4.2 ya no recibe parches de seguridad y Node 18 está fuera de soporte | Verificar con `docker compose build` en tu máquina |
| Frontend en JavaScript (sin `vue-tsc`) | El build fallaba por tipos en un proyecto casi todo JS | TypeScript se puede reintroducir por módulo |
| Tokens JWT en `localStorage` | Simplicidad | **Deuda:** migrar a cookie httpOnly (riesgo XSS) |
| `clean.sh` limitado al proyecto | El anterior hacía `prune` global y aceptaba cualquier ruta en `rm -rf` | Pide escribir el nombre del proyecto para confirmar |
| `02_deploy.sh` no corre como root; detecta Debian/Ubuntu; aborta si hay vhost duplicado | Evitar archivos de root y el 502 por `server_name` duplicado | Requiere un usuario con sudo |
| Prefijo API del módulo `roles` = `/api/security/` | Evitar `/api/roles/roles/` | Frontend usa `/security/...` |

## Anteriores (heredadas del ROADMAP original)
- 2026-08-12 — `postcss.config.js` faltante dejaba Tailwind sin compilar (corregido).
- 2026-08-12 — `conf.d/frame.conf` duplicado causó 502 por dos `server_name` iguales (corregido; ahora el deploy lo detecta).
- 2026-08-12 — Heredocs que no se guardaban a la primera: regla «verificar con `cat` antes de reconstruir».
