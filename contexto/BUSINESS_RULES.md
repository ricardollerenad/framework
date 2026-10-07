# BUSINESS_RULES — fuente de verdad

Formato: `RN-<MODULO>-<NN>: regla corta y verificable. Afecta a: <módulos>. Implementada en: <archivo>.`
Si una regla cambia: edítala aquí → anótalo en `DECISIONS.md` → revisa los módulos de «Afecta a» → actualiza código y tests.
Las reglas obsoletas se marcan `[DEPRECADA]` con fecha; nunca se borran.

## Autenticación (`authentication`)
- **RN-AUTH-01:** Access token dura 30 min; refresh token 7 días, con rotación y blacklist tras rotar. *Afecta a: todos (frontend refresca solo). Implementada en: `core/settings.py` (SIMPLE_JWT).*
- **RN-AUTH-02:** Cada login crea una `UserSession` identificada por el claim `sid`, que no cambia al refrescar. *Afecta a: auditoría. Implementada en: `authentication/views.py`, `serializers.py`.*
- **RN-AUTH-03:** `last_activity` se actualiza como máximo una vez por minuto por sesión. *Implementada en: `common/middleware.py`.*
- **RN-AUTH-04:** Logout invalida el refresh (blacklist) y cierra la sesión (`is_active=False`, `logout_at`). *Implementada en: `authentication/views.py`.*
- **RN-AUTH-05:** Ver el historial de sesiones requiere el permiso `authentication.session.view`. *Afecta a: roles.*

## Roles y permisos (`roles`)
- **RN-ROLES-01:** Los permisos se declaran en código (`apps/<m>/permissions.py`), con formato `<modulo>.<recurso>.<accion>`; los roles se crean y editan por UI/API.
- **RN-ROLES-02:** El rol `administrador` es de sistema: siempre tiene todos los permisos activos y no se puede editar ni eliminar. Ningún rol de sistema se puede eliminar.
- **RN-ROLES-03:** Un rol con usuarios asignados no se puede eliminar.
- **RN-ROLES-04:** Un usuario puede tener varios roles; sus permisos son la unión de los de todos sus roles.
- **RN-ROLES-05:** El superusuario tiene acceso total sin necesidad de roles (`'*'`).
- **RN-ROLES-06:** Un permiso que deja de declararse en código queda inactivo (deprecado), no se borra, y deja de otorgar acceso.
- **RN-ROLES-07:** Los `DEFAULT_ROLES` solo se crean si no existen; nunca sobrescriben cambios hechos desde la UI.
- **RN-ROLES-08:** Una vista sin permiso declarado deniega el acceso (fail-closed), incluso a superusuarios.

## Modularidad (transversales)
- **RN-MOD-01:** Un módulo no importa código de otro módulo.
- **RN-MOD-02:** Un módulo se engancha solo por `core/modules.py` y su `manifest.js`.
- **RN-MOD-03:** Los códigos de permiso de un módulo empiezan con el nombre del módulo.
