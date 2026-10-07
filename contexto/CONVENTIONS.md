# CONVENTIONS

## Nombres
| Cosa | Convención | Ejemplo |
|---|---|---|
| App Django / carpeta de módulo | `snake_case`, igual en back y front | `inventario` |
| Prefijo URL del módulo | `url_prefix` en `apps.py` (por defecto el nombre) | `/api/inventario/` |
| Permiso | `<modulo>.<recurso>.<accion>` en minúsculas | `inventario.producto.create` |
| Acciones estándar | `view`, `create`, `update`, `delete`, `assign`, `export` | |
| Regla de negocio | `RN-<MODULO>-<NN>` | `RN-ROLES-02` |
| Componentes Vue | `PascalCase.vue` | `ProductosView.vue` |
| Composables / stores / servicios | `useAlgo.js` / `algoStore.js` / `algoService.js` | |
| Ramas Git | `feature/<nombre>`, `fix/<nombre>` | `feature/modulo-inventario` |
| Commits | `tipo: descripción` (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`) | `feat: crud de productos` |

## Backend
- `urls.py` del módulo usa **rutas relativas**; el prefijo lo pone `core/urls.py`.
- Toda vista no pública: `permission_classes = [HasPermission]` + `required_permission` (uno) o `required_permissions` (dict por acción: `list`, `retrieve`, `create`, `update`, `partial_update`, `destroy` o acciones custom).
- Un permiso nuevo se declara en `apps/<m>/permissions.py`; se sincroniza al reiniciar el backend. El código **debe empezar con `<modulo>.`**.
- Roles por defecto: `DEFAULT_ROLES` (se crean una vez; luego se editan en la UI y no se pisan).
- Migraciones: `docker compose exec backend python manage.py makemigrations <modulo>`; se versionan en Git.
- Un módulo no importa otro módulo. Si dos lo necesitan, sube a `common/`.
- Respuestas de error: DRF estándar (`detail` o dict por campo).

## Frontend
- Los servicios usan **siempre** `shared/utils/http.js` (nunca otro axios).
- Estilos: clases Tailwind con los tokens de `docs/DESIGN.md` (`bg-humo`, `text-carbon`…), sin CSS aparte.
- Mostrar/ocultar por permiso: `const { can } = useCan()`; rutas con `meta: { permission }`; menú con `permission` en `submenus`.
- Sin `permission` en un submenú/ruta = cualquier usuario autenticado. Rutas públicas: `meta: { public: true }`.

## Tests
- Backend: `docker compose exec backend python manage.py test`. Cada módulo con reglas importantes trae su `tests.py`.
