# Contexto para programar un módulo de NEGOCIO

> Úsalo junto con `02-CONTEXTO-ARQUITECTURA.md`. Este archivo es la checklist que un módulo de negocio nuevo (ej. "inventario", "facturación", "clientes") debe cumplir para encajar en el framework sin romper convenciones.

## Checklist backend (Django)

- [ ] Nueva app en `backend/apps/<nombre_modulo>/` (nunca dentro de una app existente).
- [ ] Archivos mínimos: `models.py`, `serializers.py`, `views.py`, `urls.py`, `apps.py`, `admin.py` (si aplica), `tests/`.
- [ ] Registrar la app en `INSTALLED_APPS` (`core/settings`) y sus rutas en `core/urls.py` bajo un prefijo propio (ej. `/api/inventario/`).
- [ ] Si el módulo requiere endpoints protegidos, usar el mecanismo JWT ya existente en `apps/authentication/` — no crear autenticación propia.
- [ ] Generar migraciones (`python manage.py makemigrations <nombre_modulo>`) y confirmarlas contra una base limpia (`migrate` desde cero debe funcionar sin errores).
- [ ] Tests mínimos: al menos un test por endpoint que confirme el caso feliz y un caso de error (401/403/400).

## Checklist frontend (Vue)

- [ ] Nueva carpeta en `frontend/src/modules/<nombre_modulo>/` con subcarpetas `components/`, `views/`, y si maneja estado propio, un store de Pinia (`stores/<nombre_modulo>.ts` o dentro del propio módulo, según convención ya usada en `auth/`).
- [ ] Rutas del módulo registradas en `router/` respetando el guard de autenticación ya existente si la vista lo requiere.
- [ ] Reutilizar componentes de `shared/` en vez de duplicar UI ya existente (botones, tablas, modales, etc.).
- [ ] Usar Tailwind + Heroicons de forma consistente con el resto del proyecto (revisar `layouts/LayoutMain` como referencia de estilo).

## Preguntas que debes responder antes de pedirle el módulo a la IA

Cuanto más completes esto, menos iteraciones de ida y vuelta vas a necesitar:

1. **Nombre del módulo y qué problema resuelve** (una frase).
2. **Modelos de datos**: entidades principales y sus campos clave, y relaciones entre ellas.
3. **Endpoints necesarios**: qué operaciones expone (listar, crear, editar, eliminar, acciones especiales) y quién puede usarlas (todos los usuarios autenticados / solo admin / roles específicos).
4. **Pantallas del frontend**: qué vistas necesita el usuario (listado, detalle, formulario de creación/edición) y si depende de datos de otro módulo ya existente.
5. **Reglas de negocio específicas** que no se deducen solo del modelo de datos (ej. "no se puede eliminar un producto con stock reservado").

## Plantilla de prompt para pedirle el módulo a la IA

```
Sigue las convenciones de 02-CONTEXTO-ARQUITECTURA.md y la checklist de 03-CONTEXTO-MODULO-NEGOCIO.md.

Módulo: <nombre>
Qué resuelve: <descripción breve>

Modelos de datos:
- <entidad 1>: <campos>
- <entidad 2>: <campos>
Relaciones: <descripción>

Endpoints necesarios:
- <verbo> <ruta> -> <qué hace> (permisos: <quién puede usarlo>)

Pantallas frontend:
- <vista 1>: <qué muestra/permite hacer>

Reglas de negocio específicas:
- <regla 1>

Genera backend (app Django completa) y frontend (módulo Vue completo) siguiendo exactamente la estructura de carpetas descrita.
```
