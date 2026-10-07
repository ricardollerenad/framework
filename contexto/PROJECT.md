# PROJECT — visión, reglas generales y protocolo de chat

> Pega este archivo al inicio de cada chat nuevo (o déjalo como `CLAUDE.md` si usas Claude Code).

## Visión
Plantilla base para construir sistemas de gestión **por módulos independientes**, con **roles y permisos** configurables: los permisos se declaran en código y los roles se arman y modifican desde la interfaz sin tocar código.

## Stack
Django 5.2 + DRF + SimpleJWT + PostgreSQL · Vue 3 + Vite + Pinia + Tailwind · Docker Compose · Nginx (host) + Certbot.

## Reglas generales (innegociables)
1. **Un módulo a la vez.** No modifiques otros módulos para avanzar en el actual.
2. **Un módulo no importa código de otro módulo.** Lo compartido vive en `backend/common/` o `frontend/src/shared/`.
3. **Todo módulo se engancha por un solo punto:** `backend/core/modules.py` (lista) y `frontend/src/modules/<m>/manifest.js` (auto-descubierto).
4. **Toda vista protegida declara su permiso** (`HasPermission`). Sin permiso declarado = acceso denegado (fail-closed).
5. **Las reglas de negocio viven en `BUSINESS_RULES.md` con ID.** Si cambia una regla: se edita ahí, se anota en `DECISIONS.md`, se actualiza código y tests.
6. **Reglas obsoletas se marcan `[DEPRECADA]`, nunca se borran.** Igual con permisos: dejan de declararse y quedan inactivos.
7. **Verifica siempre lo que escribes** (`cat archivo`) antes de reconstruir contenedores.
8. **Nunca subas secretos** (`.env`) a Git.

## Roles de la aplicación (RBAC) en una línea
`Permiso` (código `modulo.recurso.accion`, declarado en `apps/<m>/permissions.py`) → agrupado en `Rol` (editable en UI) → asignado a `Usuario`. Superusuario = acceso total. Detalle: `docs/modules/roles.md`.

## Protocolo de chat nuevo
**Al empezar** pega, en este orden:
1. `docs/PROJECT.md` (este archivo)
2. `docs/CONVENTIONS.md`
3. `docs/STATUS.md`
4. `docs/modules/<modulo_actual>.md`
5. Solo los archivos de código que vayas a tocar (no el proyecto entero)

Y escribe qué módulo vas a trabajar y cuál es el objetivo de la sesión.

**Al terminar** pide: «Actualiza `STATUS.md`, `docs/modules/<modulo>.md` y, si corresponde, `BUSINESS_RULES.md` y `DECISIONS.md`», y copia esos archivos al repo antes de cerrar el chat.

## Cómo se construyó esta base (prompt maestro por fases)
1. Tipo de proyecto → 2. Arquitectura → 3. Módulos y patrón → 4. Archivos `.md` → 5. Tutorial local → GitHub → VPS.
Para un proyecto distinto, reutiliza el prompt maestro en un chat nuevo y reemplaza estos documentos.
