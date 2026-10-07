# ARCHITECTURE

**Arquitectura:** monolito modular — API REST (Django) + SPA (Vue), cada dominio es un módulo autocontenido.
**Patrón en capas dentro de cada módulo:** `urls → views → serializers → models` (y `services.py` cuando la lógica crece; las vistas no contienen lógica de negocio compleja).

## Backend
```
backend/
├── core/                 # SOLO configuración
│   ├── modules.py        # ★ lista de módulos habilitados (único enganche)
│   ├── settings.py       # INSTALLED_APPS se arma desde modules.py
│   └── urls.py           # /api/<url_prefix>/ se arma desde modules.py
├── common/               # Reutilizable ENTRE módulos (no es una app)
│   ├── rbac.py           # motor de permisos (get_user_permission_codes, user_has_permission)
│   ├── permissions.py    # HasPermission (clase DRF, fail-closed)
│   ├── middleware.py     # SessionActivityMiddleware
│   └── pagination.py
└── apps/<modulo>/        # apps.py (label + url_prefix) · models · serializers · views · urls
    └── permissions.py    # catálogo: PERMISSIONS y DEFAULT_ROLES del módulo
```
Módulos incluidos: `health`, `authentication`, `roles` (ver `docs/modules/`).

## Frontend
```
frontend/src/
├── modules/
│   ├── registry.js       # ★ auto-descubre modules/*/manifest.js
│   └── <modulo>/         # manifest.js · views/ · components/ · stores/ · services/
├── shared/               # utils (http.js, tokens.js, errors.js) · composables (useCan, useNavigation) · components
├── layouts/LayoutMain.vue
└── router/index.js       # arma rutas desde los manifests + guard de auth y permisos
```
El **menú** y las **rutas** salen de los `manifest.js`; el menú se filtra con los permisos del usuario.

## Cómo se engancha un módulo
| Dónde | Qué | Quién lo hace |
|---|---|---|
| `backend/core/modules.py` | una línea con el nombre | `new-module.sh` |
| `frontend/src/modules/<m>/manifest.js` | se auto-descubre | no requiere edición central |

Borrar un módulo = borrar sus 2 carpetas + su línea en `modules.py`.

## Flujo de autorización
1. `POST /api/auth/login/` → JWT con claim `sid` (id de sesión estable) y registro en `UserSession`.
2. `GET /api/auth/me/` → usuario + `roles` + `permissions` (superusuario: `['*']`).
3. Front: `authStore.can(codigo)` oculta menú/botones; el router bloquea rutas con `meta.permission`.
4. Back: `HasPermission` valida cada petición (la UI no es seguridad, solo comodidad).

## Puertos y Nginx
| Servicio | Puerto host (127.0.0.1) | Notas |
|---|---|---|
| backend | `BACKEND_PORT` (def. 8001) | gunicorn |
| frontend | `FRONTEND_PORT` (def. 8081) | Nginx del contenedor: SPA + proxy de `/api`, `/admin`, `/static` |
| adminer | `ADMINER_PORT` (def. 8082) | en producción solo vía `/adminer/` con clave |

- **Local:** entra por `http://localhost:<FRONTEND_PORT>`; no necesitas Nginx en tu PC.
- **Producción:** el Nginx del host (plantilla `nginx-host/vhost.conf.template`) envía `/api|/admin|/static` al backend, `/adminer/` a Adminer (con clave) y `/` al frontend. Certbot añade HTTPS.
- Un solo archivo de vhost por dominio, en `sites-available` + `sites-enabled` (nunca también en `conf.d`).
