# MODULES_GUIDE — cómo agregar un módulo

Principio: **cada pestaña del menú es un módulo encapsulado**. Se engancha en un solo punto por lado y se puede borrar sin dejar rastro.

## Camino rápido
```bash
./scripts/new-module.sh inventario "Inventario"
docker compose restart backend                                  # sincroniza permisos
docker compose exec backend python manage.py makemigrations inventario   # si agregas modelos
docker compose up -d --build frontend                           # o: cd frontend && npm run dev
```
Luego entra a **Seguridad → Roles** y asigna `inventario.item.view` a un rol (el superusuario ya lo ve).

## Qué genera
```
backend/apps/inventario/     apps.py (label + url_prefix) · models · permissions.py · views · urls
frontend/src/modules/inventario/   manifest.js · views/ · components/ · stores/ · services/
docs/modules/inventario.md
backend/core/modules.py      + 'inventario',
```

## Hacerlo a mano
1. **Backend:** crea `apps/<m>/` con `apps.py` (`name='apps.<m>'`, `label='<m>'`, `url_prefix='<m>'`), `urls.py` con rutas **relativas**, y agrega `'<m>'` a `ENABLED_MODULES`.
2. **Permisos:** en `apps/<m>/permissions.py` declara `PERMISSIONS = [('<m>.<recurso>.<accion>', 'Descripción')]`.
3. **Vistas protegidas:**
```python
class ProductoViewSet(ModelViewSet):
    permission_classes = [HasPermission]
    required_permissions = {
        'list': 'inventario.producto.view', 'retrieve': 'inventario.producto.view',
        'create': 'inventario.producto.create',
        'update': 'inventario.producto.update', 'partial_update': 'inventario.producto.update',
        'destroy': 'inventario.producto.delete',
    }
```
4. **Roles por defecto (opcional):** `DEFAULT_ROLES = {'bodeguero': {'name': 'Bodeguero', 'permissions': ['inventario.producto.view', ...]}}`. Se crean una vez; luego se editan en la UI.
5. **Frontend:** `manifest.js` con `key, label, icon, order, submenus, routes` (ver `modules/roles/manifest.js` como ejemplo). Servicios con `shared/utils/http.js`.
6. **Botones por permiso:** `const { can } = useCan()` → `v-if="can('inventario.producto.create')"`.

## Cambiar permisos o roles después
| Quiero… | Hago… |
|---|---|
| Un permiso nuevo | Lo agrego a `permissions.py` y reinicio el backend |
| Quitar un permiso | Lo borro de `permissions.py`; queda inactivo (RN-ROLES-06) |
| Un rol nuevo o cambiar sus permisos | Desde Seguridad → Roles (sin código) |
| Que un rol exista siempre al instalar | `DEFAULT_ROLES` |
| Cambiar a qué rol pertenece un usuario | Seguridad → Usuarios y roles |

## Checklist al crear un módulo
- [ ] ¿Usa `shared/utils/http.js` y `common/` en vez de duplicar lógica?
- [ ] ¿Cada vista declara su permiso? (si no, se deniega)
- [ ] ¿Los códigos de permiso empiezan con el nombre del módulo?
- [ ] ¿`urls.py` usa rutas relativas y `routes` del manifest absolutas (`/<modulo>/...`)?
- [ ] ¿Nada importa código de otro módulo?
- [ ] ¿Reglas en `BUSINESS_RULES.md`, doc en `docs/modules/<m>.md`, `STATUS.md` actualizado?
- [ ] ¿Migraciones creadas y versionadas?
