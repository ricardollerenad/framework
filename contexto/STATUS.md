# STATUS

> Léelo primero en cada chat nuevo. Al cerrar una sesión: actualízalo.
> Convención: ✅ hecho y probado · 🔄 en progreso · ⬜ pendiente · ⚠️ escrito pero NO probado en entorno real

**Última actualización:** 6 de octubre de 2026
**Módulo en curso:** ninguno (base v2 terminada)

## Fases
**Fase 0 — Base** ✅ scaffold, deploy, Nginx host + Certbot, documentación.
**Fase 1 — Reestructuración modular** ✅ `apps/health`, `common/`, `modules/`, `layouts/`.
**Fase 2 — Autenticación JWT + sesiones** ✅ login/refresh/logout/me, `UserSession`, middleware, frontend de auth.
**Fase 3 — Roles y permisos + registro modular** ✅ (código y tests)
- ✅ Modelos `AccessPermission`, `Role`, `UserRole` + migraciones
- ✅ `sync_permissions` (catálogo en código, roles por defecto, deprecación)
- ✅ `HasPermission` fail-closed y `/api/auth/me/` con roles y permisos
- ✅ API `/api/security/` (roles, permisos, asignación a usuarios)
- ✅ Registro único de módulos (`core/modules.py`, `registry.js` auto-descubierto)
- ✅ Menú y rutas filtrados por permisos; UI de Roles y Usuarios-y-roles
- ✅ `scripts/new-module.sh` (back + front + doc)
- ✅ 7 tests de backend en verde; build de Vite en verde (con y sin módulo generado)
- ⚠️ **No probado en entorno real:** `docker compose up`, `02_deploy.sh` en un VPS, Certbot, imágenes Docker.

## Pendiente (en orden)
1. ⬜ **Prueba real:** `./01_crear.sh` → `docker compose up -d --build` → `createsuperuser` → entrar al front y crear un rol.
2. ⬜ Módulo `usuarios` (crear/editar/desactivar usuarios desde la UI; hoy se crean con `createsuperuser`/admin).
3. ⬜ Fase 4 — GitHub Actions + `docker-compose.prod.yml` con imágenes de GHCR (ver `GITHUB_WORKFLOW.md`).
4. ⬜ UI de auditoría de sesiones (el endpoint `/api/auth/sessions/` ya existe).
5. ⬜ Responsive (sidebar colapsable), dropdown de usuario con avatar.
6. ⬜ Deuda: tokens a cookie httpOnly; tests de frontend (vitest); dark mode.

## Próximo paso exacto
Ejecutar la prueba real (punto 1) y pegar aquí cualquier error para corregirlo antes de crear el primer módulo de negocio.
