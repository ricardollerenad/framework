# 🗺️ Hoja de Ruta

Este documento es la fuente de verdad del avance del proyecto. Cada vez que se complete una fase, marcar el checkbox y anotar la fecha. Si retomas el proyecto en una sesión nueva (contigo o con Claude), **lee este archivo primero**, y después `docs/FASE2_AUTH.md` si estás retomando la Fase 2.

> Convención: ✅ = terminado y probado en local · 🔄 = en progreso · ⬜ = pendiente

---

## Fase 0 — Base del proyecto
- ✅ Scaffold inicial (`01-scaffold.sh`): Django + Vue + Docker Compose
- ✅ Script de despliegue (`02-deploy.sh`): Nginx host + Certbot + firewall + instala Nginx si falta
- ✅ Fix: `postcss.config.js` faltante (Tailwind no se compilaba — CSS quedaba en 57 bytes sin procesar)
- ✅ Fix: `conf.d/frame.conf` duplicado causando 502 (dos server blocks con mismo server_name)
- ✅ Documentación base (`README.md`, `ROADMAP.md`, `ARCHITECTURE.md`, `GITHUB_WORKFLOW.md`)

## Fase 1 — Reestructuración modular ✅ COMPLETA (12 ago 2026)
- ✅ Backend: `api/` → `apps/health/` (con `apps.py`, `label='health'` explícito)
- ✅ Backend: esqueleto `apps/authentication/` creado
- ✅ Backend: carpeta `common/` con `permissions.py`, `pagination.py`, `mixins.py` (placeholders)
- ✅ Backend: `core/urls.py` actualizado — cada app usa rutas relativas (`''`, no `'health/'` repetido)
- ✅ Frontend: `views/DashboardView.vue` → `modules/dashboard/views/`
- ✅ Frontend: `modules/dashboard/routes.js` (rutas propias del módulo)
- ✅ Frontend: `router/index.js` importa rutas de cada módulo
- ✅ Frontend: `components/LayoutMain.vue` → `layouts/LayoutMain.vue`
- ✅ Frontend: carpetas `shared/components`, `shared/composables`, `shared/utils` creadas (vacías, listas para Fase 3)
- ✅ Verificado: `curl http://127.0.0.1:8001/api/health/` → `{"status":"ok"}`
- ✅ Verificado: frontend carga con estilos y dashboard visible

⚠️ **Lección aprendida en esta fase:** varios heredocs (`cat > archivo <<'EOF'`) no se guardaron a la primera (quedaron con contenido viejo/vacío) sin dar error visible hasta el rebuild. Regla adoptada desde aquí: **siempre verificar con `cat archivo` inmediatamente después de escribirlo**, antes de reconstruir.

## Fase 2 — Autenticación JWT + Sesiones/Trazabilidad ✅ COMPLETA (12 ago 2026)
- ✅ Modelo `UserSession` (`apps/authentication/models.py`)
- ✅ `rest_framework_simplejwt.token_blacklist` agregado a `INSTALLED_APPS`
- ✅ Config `SIMPLE_JWT` en `settings.py` (access 30min, refresh 7 días, rotación + blacklist)
- ✅ `UserProfileSerializer` (`apps/authentication/serializers.py`)
- ✅ Vistas: `LoginView` (registra sesión), `LogoutView` (blacklist + cierra sesión), `MeView`
- ✅ `apps/authentication/urls.py`: `/api/auth/login/`, `/refresh/`, `/logout/`, `/me/`
- ✅ `common/middleware.py`: `SessionActivityMiddleware` (actualiza `last_activity` en cada request autenticado), registrado en `MIDDLEWARE`
- ✅ Migraciones generadas y aplicadas (`authentication.0001_initial`, `token_blacklist.*`)
- ✅ Superusuario de prueba creado, login/me probados con curl
- ✅ Frontend: `shared/utils/http.js` — cliente axios con interceptor de refresh automático + cola de reintentos
- ✅ Frontend: `modules/auth/` — `authService.js`, `authStore.js` (Pinia), `LoginView.vue`, `routes.js`
- ✅ Frontend: `router/index.js` con guard de autenticación (redirige a `/login`, soporta `?redirect=`)
- ✅ Frontend: `App.vue` simplificado a `<router-view />`, el layout ahora es una ruta padre
- ✅ Frontend: `main.js` restaura el usuario (`fetchMe()`) al recargar si hay token guardado
- ✅ Frontend: `shared/components/TopbarUserMenu.vue` — nombre de usuario + botón de cerrar sesión, integrado en `LayoutMain.vue`
- ✅ Verificado: redirect a `/login` sin sesión, login funcional, sesión persiste en F5, logout funcional

📄 **Contenido exacto de todos los archivos del backend de esta fase:** ver `docs/FASE2_AUTH.md` (código del frontend documentado en esta sección del roadmap; si crece mucho más se separa a su propio snapshot)

## Fase 3 — Layout tipo Odoo (sidebar + submenús + avatar) 🔄 EN PROGRESO
- ⬜ Formalizar `stores/navigation.js` con la estructura real de módulos + submenús (ver `docs/MODULES_GUIDE.md`)
- ⬜ Integrar Heroicons en cada item del sidebar
- ⬜ `TopbarUserMenu.vue`: convertir de botón simple a dropdown con avatar (iniciales o imagen) + nombre + perfil + logout
- ⬜ Responsive: sidebar colapsable en móvil (drawer/hamburguesa)
- ⬜ Script generador `new-module.sh`: crea el esqueleto de carpetas (`views/`, `components/`, `stores/`, `services/`, `routes.js`) de un módulo nuevo con un solo comando

📄 **Patrón de módulos encapsulados (cómo agregar un módulo nuevo sin tocar otros):** ver `docs/MODULES_GUIDE.md`

## Fase 4 — Imagen Docker + GitHub Container Registry
- ⬜ GitHub Actions: build + push automático a `ghcr.io` al hacer tag de versión
- ⬜ `docker-compose.prod.yml` usando `image:` en vez de `build:`
- ⬜ Probar despliegue en un servidor limpio solo con `docker compose pull`

## Fase 5 — Pulido y extras (backlog, sin orden fijo)
- ⬜ Rediseño visual (el usuario pidió posponerlo hasta tener funcionalidad completa)
- ⬜ Paginación estándar en API
- ⬜ Manejo global de errores en frontend (toast/notificaciones)
- ⬜ Dark mode
- ⬜ Tests (pytest backend / vitest frontend)

---

## 📍 Estado actual
**Estamos en:** Fase 3 — layout tipo Odoo. Fases 1 y 2 completas y verificadas (backend + frontend de auth funcionando end-to-end).
**Última actualización:** 13 de agosto de 2026
**Próximo paso inmediato:** formalizar `stores/navigation.js` con la estructura de módulos + submenús descrita en `docs/MODULES_GUIDE.md`, luego integrar Heroicons.