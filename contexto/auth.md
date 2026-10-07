# Módulo: Autenticación (`authentication` / front `auth`)

> Reemplaza a `Fase2_auth.md`. Aquí va el **contrato**; el código vive en el repo (no se pega aquí para que no se desactualice).

## Objetivo
Login con JWT, renovación automática, cierre de sesión y trazabilidad de sesiones.

## Alcance
- Entra: login, refresh, logout, perfil con roles y permisos, auditoría de sesiones.
- No entra: crear/editar usuarios (módulo `usuarios`, pendiente), recuperación de contraseña.

## Modelos
`UserSession(user, session_id=sid, ip_address, user_agent, login_at, last_activity, logout_at, is_active)`.

## Endpoints (prefijo `/api/auth/`)
| Método | Ruta | Permiso | Descripción |
|---|---|---|---|
| POST | `login/` | público | `{username,password}` → `access`, `refresh`; crea `UserSession` |
| POST | `refresh/` | público | `{refresh}` → nuevo `access` y `refresh` (rotación) |
| POST | `logout/` | autenticado | `{refresh}` + `Authorization: Bearer <access>`; blacklist + cierra sesión |
| GET | `me/` | autenticado | `id, username, email, first_name, last_name, is_superuser, roles[], permissions[]` |
| GET | `sessions/` | `authentication.session.view` | Lista paginada de sesiones |

## Permisos que declara
`authentication.session.view`

## Frontend
- `modules/auth/`: `LoginView`, `ForbiddenView` (403), `authStore` (`login`, `logout`, `fetchMe`, `can`), `authService`.
- `shared/utils/http.js`: adjunta el Bearer y renueva el access una sola vez ante un 401 (las peticiones simultáneas comparten la renovación).
- `router/index.js`: guard de autenticación (`?redirect=` validado) y de permisos (`meta.permission` → 403).

## Reglas
RN-AUTH-01 … RN-AUTH-05 (ver `BUSINESS_RULES.md`).

## Dependencias
Solo `common/` (`rbac.py`, `permissions.py`, `middleware.py`).

## Prueba rápida
```bash
curl -s -X POST http://127.0.0.1:8001/api/auth/login/ -H "Content-Type: application/json" \
  -d '{"username":"TU_USUARIO","password":"TU_PASSWORD"}'
curl -s http://127.0.0.1:8001/api/auth/me/ -H "Authorization: Bearer <access>"
```

## Checklist
- [x] Backend + tests · [x] Frontend · [ ] UI de auditoría de sesiones · [ ] Tokens a cookie httpOnly
