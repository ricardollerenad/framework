# Módulo: Roles y permisos (`roles`) — API en `/api/security/`

## Objetivo
Definir **qué puede hacer cada usuario**: permisos declarados en código, roles editables desde la interfaz, asignación de roles a usuarios.

## Alcance
- Entra: catálogo de permisos, CRUD de roles, asignación usuario↔roles, `sync_permissions`.
- No entra: crear usuarios (módulo `usuarios`), permisos por objeto/fila.

## Modelos
- `AccessPermission(code, module, description, is_active)` — catálogo; `is_active=False` = deprecado.
- `Role(name, slug, description, is_system, permissions M2M)`.
- `UserRole(user, role, assigned_by, assigned_at)` — único por (user, role).

## Endpoints (prefijo `/api/security/`)
| Método | Ruta | Permiso | Descripción |
|---|---|---|---|
| GET | `roles/` | `roles.role.view` | Lista con `user_count` (sin paginar) |
| POST | `roles/` | `roles.role.create` | `{name, description, permissions:[códigos]}` |
| PATCH/PUT | `roles/<id>/` | `roles.role.update` | No permitido sobre `administrador` |
| DELETE | `roles/<id>/` | `roles.role.delete` | No si es de sistema o tiene usuarios |
| GET | `permissions/` | `roles.permission.view` | Catálogo activo |
| GET | `users/` | `roles.userrole.view` | Usuarios con sus roles |
| PUT | `users/<id>/roles/` | `roles.userrole.assign` | `{roles:[ids]}` reemplaza la asignación |

## Permisos que declara
`roles.role.{view,create,update,delete}`, `roles.permission.view`, `roles.userrole.{view,assign}`.

## Roles por defecto
- `administrador` (sistema): todos los permisos activos, siempre.
- `gestor-de-seguridad`: todos los permisos de este módulo (se crea una vez).

## Cómo funciona `sync_permissions` (se ejecuta en cada arranque del backend)
1. Lee `PERMISSIONS` y `DEFAULT_ROLES` de `apps/<m>/permissions.py` de cada módulo habilitado.
2. Crea/actualiza permisos; los que ya no se declaran quedan inactivos.
3. Da todos los permisos activos al rol `administrador`.
4. Crea los `DEFAULT_ROLES` que no existan (no toca los existentes).

## Frontend (`modules/roles/`)
`RolesView` (lista + matriz de permisos agrupada por módulo) y `UsersRolesView` (asignación). Los botones aparecen según `can(...)`.

## Reglas
RN-ROLES-01 … RN-ROLES-08.

## Dependencias
Solo `common/`. Los demás módulos NO dependen de este: `common/rbac.py` lo consulta por nombre.

## Checklist
- [x] Modelos, migración, API, tests (7 en verde) · [x] UI
- [ ] Auditoría de cambios de roles · [ ] Permisos por objeto (si algún módulo lo necesita)
